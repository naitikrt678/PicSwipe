import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/app_state.dart';
import 'preview_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AppState _appState = AppState();
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _unfavoriteSelected() async {
    await _appState.removeMultipleFromFavorites(_selectedIds);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedIds.length} items unfavorited.')),
      );
      _exitSelectionMode();
    }
  }

  Future<void> _shareSelected() async {
    final selectedAssets = _appState.favorites.where((e) => _selectedIds.contains(e.id)).toList();
    if (selectedAssets.isEmpty) return;

    List<XFile> filesToShare = [];
    for (var asset in selectedAssets) {
      final file = await asset.file;
      if (file != null) {
        filesToShare.add(XFile(file.path));
      }
    }

    if (filesToShare.isNotEmpty && mounted) {
      await Share.shareXFiles(filesToShare);
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : 'Favorites'),
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelectionMode,
                  )
                : null,
          ),
          body: _appState.favorites.isEmpty
              ? const Center(child: Text('No favorites yet.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _appState.favorites.length,
                  itemBuilder: (context, index) {
                    final asset = _appState.favorites[index];
                    final isSelected = _selectedIds.contains(asset.id);

                    return GestureDetector(
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(asset.id);
                          });
                        }
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(asset.id);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PreviewScreen(
                                assetList: List.from(_appState.favorites),
                                initialIndex: index,
                                source: PreviewSource.favorites,
                              ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AssetEntityImage(
                              asset,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(200),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_isSelectionMode)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.red : Colors.transparent,
                                  width: 4,
                                ),
                                color: isSelected ? Colors.red.withValues(alpha: 0.3) : Colors.black26,
                              ),
                            ),
                          if (_isSelectionMode && isSelected)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
          bottomNavigationBar: _isSelectionMode
              ? BottomAppBar(
                  color: Colors.grey[900],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : _shareSelected,
                        icon: const Icon(Icons.share, color: Colors.blue),
                        label: const Text('Share', style: TextStyle(color: Colors.blue)),
                      ),
                      TextButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : _unfavoriteSelected,
                        icon: const Icon(Icons.heart_broken, color: Colors.red),
                        label: const Text('Unfavorite', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
