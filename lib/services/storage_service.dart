import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zikir_history.dart';

class StorageService {
  static const String _historyKey = 'zikir_history';
  static const String _favoritesKey = 'favorites';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _customCountKey = 'custom_count';
  static const String _darkModeKey = 'dark_mode';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  static Future<List<ZikirHistory>> getHistory() async {
    final prefs = await _prefs;
    final data = prefs.getString(_historyKey);
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => ZikirHistory.fromMap(e)).toList();
  }

  static Future<void> saveHistory(List<ZikirHistory> history) async {
    final prefs = await _prefs;
    final data = json.encode(history.map((e) => e.toMap()).toList());
    await prefs.setString(_historyKey, data);
  }

  static Future<void> updateZikirCount(int esmaIndex, String latin, int targetCount, int currentCount) async {
    final history = await getHistory();
    final existingIndex = history.indexWhere((h) => h.esmaIndex == esmaIndex);
    final existingCompletions =
        existingIndex >= 0 ? history[existingIndex].completionCount : 0;

    final entry = ZikirHistory(
      esmaIndex: esmaIndex,
      latin: latin,
      targetCount: targetCount,
      completedCount: currentCount,
      lastDate: DateTime.now(),
      isCompleted: currentCount >= targetCount,
      completionCount: existingCompletions,
    );

    if (existingIndex >= 0) {
      history[existingIndex] = entry;
    } else {
      history.insert(0, entry);
    }

    await saveHistory(history);
  }

  /// Bir isim baştan sona tamamlandığında çağrılır; tamamlanma sayacını
  /// bir artırır ve kaydı listenin başına taşır.
  static Future<void> incrementCompletion(
      int esmaIndex, String latin, int targetCount) async {
    final history = await getHistory();
    final existingIndex = history.indexWhere((h) => h.esmaIndex == esmaIndex);
    final previousCompletions =
        existingIndex >= 0 ? history[existingIndex].completionCount : 0;

    final entry = ZikirHistory(
      esmaIndex: esmaIndex,
      latin: latin,
      targetCount: targetCount,
      completedCount: targetCount,
      lastDate: DateTime.now(),
      isCompleted: true,
      completionCount: previousCompletions + 1,
    );

    if (existingIndex >= 0) {
      history.removeAt(existingIndex);
    }
    history.insert(0, entry);

    await saveHistory(history);
  }

  static Future<List<int>> getFavorites() async {
    final prefs = await _prefs;
    final data = prefs.getStringList(_favoritesKey);
    if (data == null) return [];
    return data.map((e) => int.parse(e)).toList();
  }

  static Future<void> toggleFavorite(int esmaIndex) async {
    final prefs = await _prefs;
    final favorites = await getFavorites();

    if (favorites.contains(esmaIndex)) {
      favorites.remove(esmaIndex);
    } else {
      favorites.add(esmaIndex);
    }

    await prefs.setStringList(
      _favoritesKey,
      favorites.map((e) => e.toString()).toList(),
    );
  }

  static Future<bool> isFavorite(int esmaIndex) async {
    final favorites = await getFavorites();
    return favorites.contains(esmaIndex);
  }

  static Future<void> removeHistoryEntry(int esmaIndex) async {
    final history = await getHistory();
    history.removeWhere((h) => h.esmaIndex == esmaIndex);
    await saveHistory(history);
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_vibrationKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_vibrationKey, enabled);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_darkModeKey) ?? true;
  }

  static Future<void> setDarkMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_darkModeKey, enabled);
  }

  static Future<int> getCustomCount() async {
    final prefs = await _prefs;
    return prefs.getInt(_customCountKey) ?? 33;
  }

  static Future<void> setCustomCount(int count) async {
    final prefs = await _prefs;
    await prefs.setInt(_customCountKey, count);
  }
}
