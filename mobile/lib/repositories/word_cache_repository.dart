import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Repository for caching word data locally using shared_preferences
class WordCacheRepository {
  static const String _wordsKey = 'cached_words';
  static const String _endDateKey = 'cached_end_date';

  final SharedPreferences _prefs;

  WordCacheRepository(this._prefs);

  /// Get the cached end date
  DateTime? getCachedEndDate() {
    final endDateStr = _prefs.getString(_endDateKey);
    if (endDateStr == null) return null;
    return DateTime.tryParse(endDateStr);
  }

  /// Check if cache is valid (has data covering today and future)
  bool isCacheValid() {
    final endDate = getCachedEndDate();
    if (endDate == null) return false;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final endDateStart = DateTime(endDate.year, endDate.month, endDate.day);

    return endDateStart.isAfter(todayStart) ||
        endDateStart.isAtSameMomentAs(todayStart);
  }

  /// Get all cached words
  List<Word> getCachedWords() {
    final wordsJson = _prefs.getString(_wordsKey);
    if (wordsJson == null) return [];

    try {
      final List<dynamic> decoded = json.decode(wordsJson);
      return decoded
          .map((e) => Word.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get word for a specific date
  Word? getWordForDate(DateTime date) {
    final words = getCachedWords();
    final dateStart = DateTime(date.year, date.month, date.day);

    for (final word in words) {
      final wordDate = DateTime(word.date.year, word.date.month, word.date.day);
      if (wordDate.isAtSameMomentAs(dateStart)) {
        return word;
      }
    }
    return null;
  }

  /// Get today's word
  Word? getTodaysWord() {
    return getWordForDate(DateTime.now());
  }

  /// Save words to cache
  Future<void> saveWords(List<Word> words, DateTime endDate) async {
    final wordsJson = json.encode(words.map((w) => w.toJson()).toList());
    await _prefs.setString(_wordsKey, wordsJson);
    await _prefs.setString(_endDateKey, endDate.toIso8601String());
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _prefs.remove(_wordsKey);
    await _prefs.remove(_endDateKey);
  }

  /// Get the number of days until cache expires
  int getDaysUntilExpiry() {
    final endDate = getCachedEndDate();
    if (endDate == null) return 0;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final endDateStart = DateTime(endDate.year, endDate.month, endDate.day);

    return endDateStart.difference(todayStart).inDays;
  }
}
