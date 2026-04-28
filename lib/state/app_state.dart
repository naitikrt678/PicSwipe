import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final List<AssetEntity> recycleBin = [];
  bool isHydrated = false;

  Future<void> init() async {
    if (isHydrated) return;
    
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedIds = prefs.getStringList('recycle_bin_ids') ?? [];
    
    if (savedIds.isEmpty) {
      isHydrated = true;
      notifyListeners();
      return;
    }

    // Hydration phase
    List<String> validIds = [];
    for (String id in savedIds) {
      try {
        final AssetEntity? asset = await AssetEntity.fromId(id);
        if (asset != null) {
          final file = await asset.file;
          if (file != null && await file.exists()) {
            recycleBin.add(asset);
            validIds.add(id);
          }
        }
      } catch (e) {
        // file no longer found, simply don't add to validIds
      }
    }

    if (validIds.length != savedIds.length) {
      await prefs.setStringList('recycle_bin_ids', validIds);
    }

    isHydrated = true;
    notifyListeners();
  }

  Future<void> addToBin(AssetEntity asset) async {
    if (!recycleBin.any((e) => e.id == asset.id)) {
      recycleBin.add(asset);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> removeFromBin(AssetEntity asset) async {
    recycleBin.removeWhere((e) => e.id == asset.id);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> removeMultipleFromBin(Set<String> idsToRemove) async {
    recycleBin.removeWhere((e) => idsToRemove.contains(e.id));
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clearBin() async {
    recycleBin.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = recycleBin.map((e) => e.id).toList();
    await prefs.setStringList('recycle_bin_ids', ids);
  }
}
