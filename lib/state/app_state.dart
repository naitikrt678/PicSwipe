import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final List<AssetEntity> recycleBin = [];
  final List<AssetEntity> favorites = [];
  bool isHydrated = false;

  bool isDarkMode = true;
  bool enableDownSwipe = false;
  String totalBinSize = "0 B";

  Future<void> init() async {
    if (isHydrated) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    isDarkMode = prefs.getBool('isDarkMode') ?? true;
    enableDownSwipe = prefs.getBool('enableDownSwipe') ?? false;

    final List<String> savedIds = prefs.getStringList('recycle_bin_ids') ?? [];
    final List<String> savedFavIds = prefs.getStringList('favorites_ids') ?? [];

    List<String> validIds = [];
    for (String id in savedIds) {
      try {
        final AssetEntity? asset = await AssetEntity.fromId(id);
        if (asset != null && asset.id != 'null' && asset.id.isNotEmpty) {
          final file = await asset.file;
          if (file != null && await file.exists()) {
            recycleBin.add(asset);
            validIds.add(id);
          }
        }
      } catch (e) {
      }
    }
    if (validIds.length != savedIds.length) {
      await prefs.setStringList('recycle_bin_ids', validIds);
    }

    List<String> validFavIds = [];
    for (String id in savedFavIds) {
      try {
        final AssetEntity? asset = await AssetEntity.fromId(id);
        if (asset != null && asset.id != 'null' && asset.id.isNotEmpty) {
          final file = await asset.file;
          if (file != null && await file.exists()) {
            favorites.add(asset);
            validFavIds.add(id);
          }
        }
      } catch (e) {
      }
    }
    if (validFavIds.length != savedFavIds.length) {
      await prefs.setStringList('favorites_ids', validFavIds);
    }

    isHydrated = true;
    _calculateBinSize();
    notifyListeners();
  }

  void toggleTheme() async {
    isDarkMode = !isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  void toggleDownSwipe() async {
    enableDownSwipe = !enableDownSwipe;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableDownSwipe', enableDownSwipe);
  }

  Future<void> _calculateBinSize() async {
    int totalBytes = 0;
    for (var asset in recycleBin) {
      try {
        final file = await asset.file;
        if (file != null && await file.exists()) {
          totalBytes += await file.length();
        }
      } catch (_) {}
    }
    
    if (totalBytes < 1024) {
      totalBinSize = "$totalBytes B";
    } else if (totalBytes < 1024 * 1024) {
      totalBinSize = "${(totalBytes / 1024).toStringAsFixed(2)} KB";
    } else if (totalBytes < 1024 * 1024 * 1024) {
      totalBinSize = "${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      totalBinSize = "${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    }
    notifyListeners();
  }

  Future<void> addToBin(AssetEntity asset) async {
    if (asset.id == 'null' || asset.id.isEmpty) return;
    if (!recycleBin.any((e) => e.id == asset.id)) {
      recycleBin.add(asset);
      notifyListeners();
      await _saveToPrefs();
      _calculateBinSize();
    }
  }

  Future<void> removeFromBin(AssetEntity asset) async {
    recycleBin.removeWhere((e) => e.id == asset.id);
    notifyListeners();
    await _saveToPrefs();
    _calculateBinSize();
  }

  Future<void> removeMultipleFromBin(Set<String> idsToRemove) async {
    recycleBin.removeWhere((e) => idsToRemove.contains(e.id));
    notifyListeners();
    await _saveToPrefs();
    _calculateBinSize();
  }

  Future<void> clearBin() async {
    recycleBin.clear();
    notifyListeners();
    await _saveToPrefs();
    _calculateBinSize();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = recycleBin.map((e) => e.id).toList();
    await prefs.setStringList('recycle_bin_ids', ids);
  }

  Future<void> addToFavorites(AssetEntity asset) async {
    if (asset.id == 'null' || asset.id.isEmpty) return;
    if (!favorites.any((e) => e.id == asset.id)) {
      favorites.add(asset);
      notifyListeners();
      await _saveFavsToPrefs();
    }
  }

  Future<void> removeFromFavorites(AssetEntity asset) async {
    favorites.removeWhere((e) => e.id == asset.id);
    notifyListeners();
    await _saveFavsToPrefs();
  }

  Future<void> removeMultipleFromFavorites(Set<String> idsToRemove) async {
    favorites.removeWhere((e) => idsToRemove.contains(e.id));
    notifyListeners();
    await _saveFavsToPrefs();
  }

  Future<void> _saveFavsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = favorites.map((e) => e.id).toList();
    await prefs.setStringList('favorites_ids', ids);
  }
}
