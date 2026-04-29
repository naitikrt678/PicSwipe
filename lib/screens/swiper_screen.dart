import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../state/app_state.dart';

enum SortMode {
  dateDescending,
  dateAscending,
  random
}

class SwiperScreen extends StatefulWidget {
  final AssetPathEntity album;

  const SwiperScreen({super.key, required this.album});

  @override
  State<SwiperScreen> createState() => _SwiperScreenState();
}

class _SwiperScreenState extends State<SwiperScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  final List<AssetEntity> _assets = [];
  int _currentPage = 0;
  final int _perPage = 50;
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentIndex = 0;
  SortMode _sortMode = SortMode.dateDescending;

  @override
  void initState() {
    super.initState();
    _loadMoreAssets();
  }

  Future<void> _loadMoreAssets() async {
    if (!_hasMore) return;
    
    final FilterOptionGroup filter = FilterOptionGroup(
      orders: [
        OrderOption(
          type: OrderOptionType.createDate,
          asc: _sortMode == SortMode.dateAscending,
        )
      ],
    );

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filter,
    );
    final currentAlbum = paths.firstWhere((p) => p.id == widget.album.id, orElse: () => widget.album);

    final List<AssetEntity> assets = await currentAlbum.getAssetListPaged(
      page: _currentPage,
      size: _perPage,
    );

    final Set<String> binIds = AppState().recycleBin.map((e) => e.id).toSet();
    final Set<String> favIds = AppState().favorites.map((e) => e.id).toSet();
    assets.removeWhere((asset) => binIds.contains(asset.id) || favIds.contains(asset.id));

    if (_sortMode == SortMode.random) {
      assets.shuffle(Random.secure());
    }

    if (assets.isEmpty) {
      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _assets.addAll(assets);
        _currentPage++;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSortModeChanged(SortMode newMode) async {
    if (_sortMode == newMode) return;
    setState(() {
      _sortMode = newMode;
      _isLoading = true;
      _assets.clear();
      _currentPage = 0;
      _currentIndex = 0;
      _hasMore = true;
    });
    await _loadMoreAssets();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final asset = _assets[previousIndex];

    if (direction == CardSwiperDirection.left) {
      AppState().addToBin(asset);
    } else if (direction == CardSwiperDirection.right) {
      _setFavorite(asset);
    } else if (direction == CardSwiperDirection.top) {
      // Keep
    }

    if (currentIndex != null) {
      setState(() {
        _currentIndex = currentIndex;
      });
      if (currentIndex >= _assets.length - 10) {
        _loadMoreAssets();
      }
    }

    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex != null) {
      final asset = _assets[previousIndex];
      if (direction == CardSwiperDirection.left) {
        AppState().removeFromBin(asset);
      } else if (direction == CardSwiperDirection.right) {
        AppState().removeFromFavorites(asset);
      }
      setState(() {
        _currentIndex = previousIndex;
      });
    }
    return true;
  }

  Future<void> _setFavorite(AssetEntity asset) async {
    try {
      await AppState().addToFavorites(asset);
    } catch (e) {
      debugPrint("Could not set favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(widget.album.name),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                _swiperController.undo();
              },
            ),
            actions: [
              PopupMenuButton<SortMode>(
                initialValue: _sortMode,
                onSelected: _onSortModeChanged,
                icon: const Icon(Icons.sort),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SortMode.dateDescending,
                    child: Text('Newest First'),
                  ),
                  const PopupMenuItem(
                    value: SortMode.dateAscending,
                    child: Text('Oldest First'),
                  ),
                  const PopupMenuItem(
                    value: SortMode.random,
                    child: Text('Random Shuffle'),
                  ),
                ],
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assets.isEmpty
                  ? const Center(child: Text('End of Feed', style: TextStyle(fontSize: 18)))
                  : CardSwiper(
                      controller: _swiperController,
                      cardsCount: _assets.length,
                      onSwipe: _onSwipe,
                      onUndo: _onUndo,
                      maxAngle: 30,
                      allowedSwipeDirection: AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                        up: true,
                        down: AppState().enableDownSwipe,
                      ),
                      numberOfCardsDisplayed: 3,
                      backCardOffset: const Offset(0, 40),
                      padding: const EdgeInsets.all(24.0),
                      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                        final asset = _assets[index];
                        return MediaCard(
                          key: ValueKey(asset.id),
                          asset: asset,
                          isActive: index == _currentIndex,
                          horizontalOffsetPercentage: percentThresholdX,
                          verticalOffsetPercentage: percentThresholdY,
                        );
                      },
                    ),
        );
      },
    );
  }
}

class MediaCard extends StatefulWidget {
  final AssetEntity asset;
  final bool isActive;
  final int horizontalOffsetPercentage;
  final int verticalOffsetPercentage;

  const MediaCard({
    required this.asset,
    required this.isActive,
    required this.horizontalOffsetPercentage,
    required this.verticalOffsetPercentage,
    super.key,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = false;
  int _lastHapticDir = 0;
  final int _hapticThreshold = 40;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(MediaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _initializeVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeVideo();
    }

    if (widget.isActive) {
      int currentDir = 0;
      if (widget.horizontalOffsetPercentage > _hapticThreshold) {
        currentDir = 1;
      } else if (widget.horizontalOffsetPercentage < -_hapticThreshold) {
        currentDir = 2;
      } else if (widget.verticalOffsetPercentage < -_hapticThreshold) {
        currentDir = 3;
      }

      if (currentDir != 0 && _lastHapticDir != currentDir) {
        HapticFeedback.mediumImpact();
        _lastHapticDir = currentDir;
      } else if (currentDir == 0 && _lastHapticDir != 0) {
        _lastHapticDir = 0;
      }
    }
  }

  @override
  void dispose() {
    _disposeVideo(isDisposing: true);
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.asset.type != AssetType.video) return;
    final file = await widget.asset.file;
    if (file == null || !mounted) return;

    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    if (!mounted) return;

    _videoController!.setVolume(_isMuted ? 0 : 1);
    _videoController!.setLooping(true);

    setState(() {
      _isVideoInitialized = true;
    });
  }

  void _disposeVideo({bool isDisposing = false}) {
    if (_videoController == null) return;
    _videoController?.dispose();
    _videoController = null;
    if (!isDisposing && mounted) {
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double xPercent = widget.horizontalOffsetPercentage / 100.0;
    double yPercent = widget.verticalOffsetPercentage / 100.0;

    String overlayText = "";
    Color overlayColor = Colors.transparent;

    if (xPercent.abs() > yPercent.abs()) {
      if (xPercent > 0) {
        overlayText = "FAVORITE";
        overlayColor = Colors.green;
      } else if (xPercent < 0) {
        overlayText = "RECYCLE";
        overlayColor = Colors.red;
      }
    } else {
      if (yPercent < 0) {
        overlayText = "KEEP";
        overlayColor = Colors.blue;
      }
    }

    double intensity = max(xPercent.abs(), yPercent.abs()).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetEntityImage(
            widget.asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(100),
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

          if (widget.asset.type == AssetType.video && _isVideoInitialized && _videoController != null)
            VisibilityDetector(
              key: Key(widget.asset.id),
              onVisibilityChanged: (info) {
                if (info.visibleFraction >= 0.8) {
                  _videoController?.play();
                } else {
                  _videoController?.pause();
                }
              },
              child: IgnorePointer(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            )
          else
            AssetEntityImage(
              widget.asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(1000),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error, color: Colors.white));
              },
            ),

          if (widget.asset.type == AssetType.video && _isVideoInitialized && _videoController != null)
            ...[
              Positioned(
                right: 16,
                bottom: 32,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        _videoController!.setVolume(_isMuted ? 0 : 1);
                      });
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 4,
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: false,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white54,
                    ),
                  ),
                ),
              ),
            ],

          if (intensity > 0)
            Center(
              child: Opacity(
                opacity: (intensity * 0.7).clamp(0.0, 0.7),
                child: Transform.scale(
                  scale: 0.5 + (intensity * 0.5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      border: Border.all(color: overlayColor, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      overlayText,
                      style: TextStyle(
                        color: overlayColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
