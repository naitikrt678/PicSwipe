import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:video_player/video_player.dart';
import '../state/app_state.dart';

class PreviewScreen extends StatefulWidget {
  final AssetEntity asset;

  const PreviewScreen({super.key, required this.asset});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = true;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.asset.type == AssetType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    final file = await widget.asset.file;
    if (file == null || !mounted) return;

    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    if (!mounted) return;

    _videoController!.setVolume(_isMuted ? 0 : 1);
    _videoController!.setLooping(true);
    _videoController!.play();

    setState(() {
      _isVideoInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
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

  Future<void> _restoreAsset() async {
    await AppState().removeFromBin(widget.asset);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteAsset() async {
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
        final result = await PhotoManager.editor.deleteWithIds([widget.asset.id]);
        if (result.isNotEmpty) {
          await AppState().removeFromBin(widget.asset);
          if (mounted) {
            Navigator.pop(context);
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Preview'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: widget.asset.type == AssetType.video
                    ? (_isVideoInitialized && _videoController != null
                        ? GestureDetector(
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
                          )
                        : const CircularProgressIndicator(color: Colors.white))
                    : AssetEntityImage(
                        widget.asset,
                        isOriginal: true,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error, color: Colors.white));
                        },
                      ),
              ),
            ),
            if (widget.asset.type == AssetType.video && _isVideoInitialized && _videoController != null)
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
              child: Row(
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
