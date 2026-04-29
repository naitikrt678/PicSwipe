import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';

enum PreviewSource { recycleBin, favorites }

class PreviewScreen extends StatefulWidget {
  final List<AssetEntity> assetList;
  final int initialIndex;
  final PreviewSource source;

  const PreviewScreen({
    super.key,
    required this.assetList,
    required this.initialIndex,
    required this.source,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = false;
  bool _isPlaying = true;
  
  String _currentFileSize = "";

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _onPageChanged(_currentIndex);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _disposeVideo();
    
    final asset = widget.assetList[_currentIndex];
    if (asset.type == AssetType.video) {
      _initializeVideo(asset);
    }
    
    if (widget.source == PreviewSource.recycleBin) {
      _calculateFileSize(asset);
    }
  }

  Future<void> _calculateFileSize(AssetEntity asset) async {
    setState(() => _currentFileSize = "Calculating...");
    try {
      final file = await asset.file;
      if (file != null) {
        final totalBytes = await file.length();
        String size;
        if (totalBytes < 1024) {
          size = "$totalBytes B";
        } else if (totalBytes < 1024 * 1024) {
          size = "${(totalBytes / 1024).toStringAsFixed(2)} KB";
        } else if (totalBytes < 1024 * 1024 * 1024) {
          size = "${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
        } else {
          size = "${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
        }
        
        if (mounted && widget.assetList[_currentIndex].id == asset.id) {
          setState(() => _currentFileSize = size);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _currentFileSize = "Unknown");
    }
  }

  Future<void> _initializeVideo(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null || !mounted || widget.assetList[_currentIndex].id != asset.id) return;

    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    if (!mounted || widget.assetList[_currentIndex].id != asset.id) {
      _videoController?.dispose();
      _videoController = null;
      return;
    }

    _videoController!.setVolume(_isMuted ? 0 : 1);
    _videoController!.setLooping(true);
    _videoController!.play();

    setState(() {
      _isVideoInitialized = true;
      _isPlaying = true;
    });
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _isPlaying = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0 : 1);
    });
  }

  AssetEntity get _currentAsset => widget.assetList[_currentIndex];

  Future<void> _restoreAsset() async {
    final asset = _currentAsset;
    await AppState().removeFromBin(asset);
    _handleRemoval(asset);
  }

  Future<void> _deleteAsset() async {
    final asset = _currentAsset;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to permanently delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final result = await PhotoManager.editor.deleteWithIds([asset.id]);
        if (result.isNotEmpty) {
          await AppState().removeFromBin(asset);
          _handleRemoval(asset);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete item: $e')),
          );
        }
      }
    }
  }

  Future<void> _unfavoriteAsset() async {
    final asset = _currentAsset;
    try {
      await AppState().removeFromFavorites(asset);
      _handleRemoval(asset);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unfavorite: $e')),
        );
      }
    }
  }

  void _handleRemoval(AssetEntity asset) {
    if (!mounted) return;
    
    setState(() {
      widget.assetList.removeWhere((e) => e.id == asset.id);
      
      if (widget.assetList.isEmpty) {
        Navigator.pop(context);
        return;
      }
      
      if (_currentIndex >= widget.assetList.length) {
        _currentIndex = widget.assetList.length - 1;
      }
      
      _onPageChanged(_currentIndex);
    });
  }

  Future<void> _shareAsset() async {
    final file = await _currentAsset.file;
    if (file != null && mounted) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _openGallery() async {
    final asset = _currentAsset;
    final file = await asset.file;
    if (file != null) {
      if (Platform.isAndroid) {
        try {
          final String mediaType = asset.type == AssetType.video ? 'video' : 'images';
          final uri = Uri.parse('content://media/external/$mediaType/media/${asset.id}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (_) {}
      }
      await OpenFilex.open(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetList.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${_currentIndex + 1} of ${widget.assetList.length}'),
        actions: [
          if (widget.source == PreviewSource.favorites)
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: _unfavoriteAsset,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.source == PreviewSource.recycleBin && _currentFileSize.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('Size: $_currentFileSize', style: const TextStyle(color: Colors.white70)),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: widget.assetList.length,
                itemBuilder: (context, index) {
                  final asset = widget.assetList[index];
                  
                  if (asset.type == AssetType.video && index == _currentIndex && _isVideoInitialized && _videoController != null) {
                    return Center(
                      child: GestureDetector(
                        key: ValueKey(asset.id),
                        onTap: _togglePlay,
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              if (!_isPlaying)
                                const Icon(Icons.play_circle_filled, size: 80, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (asset.type == AssetType.video) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  } else {
                    return InteractiveViewer(
                      key: ValueKey(asset.id),
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: AssetEntityImage(
                        asset,
                        isOriginal: true,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error, color: Colors.white));
                        },
                      ),
                    );
                  }
                },
              ),
            ),
            if (_currentAsset.type == AssetType.video && _isVideoInitialized && _videoController != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: _togglePlay,
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.blue,
                          backgroundColor: Colors.white24,
                          bufferedColor: Colors.white54,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: _toggleMute,
                    ),
                  ],
                ),
              ),
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: widget.source == PreviewSource.favorites
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: _shareAsset,
                          icon: const Icon(Icons.share, color: Colors.blue),
                          label: const Text('Share', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ),
                        TextButton.icon(
                          onPressed: _openGallery,
                          icon: const Icon(Icons.open_in_new, color: Colors.green),
                          label: const Text('Gallery', style: TextStyle(color: Colors.green, fontSize: 16)),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: _restoreAsset,
                          icon: const Icon(Icons.restore, color: Colors.blue),
                          label: const Text('Restore', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        ),
                        TextButton.icon(
                          onPressed: _deleteAsset,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 16)),
                        ),
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }
}
