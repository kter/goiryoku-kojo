import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Repository for storing and retrieving game scores locally
class ScoreRepository {
  static const String _scoresKey = 'game_scores';
  static const int _maxScores = 100; // Keep last 100 scores

  final SharedPreferences _prefs;

  ScoreRepository(this._prefs);

  /// Get all stored scores
  List<GameScore> getAllScores() {
    final scoresJson = _prefs.getString(_scoresKey);
    if (scoresJson == null) return [];

    try {
      final List<dynamic> decoded = json.decode(scoresJson);
      return decoded
          .map((e) => GameScore.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt)); // Newest first
    } catch (e) {
      return [];
    }
  }

  /// Get scores filtered by game type
  List<GameScore> getScoresByGameType(GameType gameType) {
    return getAllScores().where((s) => s.gameType == gameType).toList();
  }

  /// Get scores for a specific date range
  List<GameScore> getScoresInRange(DateTime start, DateTime end) {
    return getAllScores().where((s) {
      return s.playedAt.isAfter(start) && s.playedAt.isBefore(end);
    }).toList();
  }

  /// Get recent scores (last N days)
  List<GameScore> getRecentScores({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return getAllScores().where((s) => s.playedAt.isAfter(cutoff)).toList();
  }

  /// Save a new score
  Future<void> saveScore(GameScore score) async {
    final scores = getAllScores();
    scores.insert(0, score);

    // Keep only the most recent scores
    final trimmedScores = scores.take(_maxScores).toList();

    final scoresJson =
        json.encode(trimmedScores.map((s) => s.toJson()).toList());
    await _prefs.setString(_scoresKey, scoresJson);
  }

  /// Clear all scores
  Future<void> clearScores() async {
    await _prefs.remove(_scoresKey);
  }

  /// Get average score by game type
  double getAverageScore(GameType gameType) {
    final scores = getScoresByGameType(gameType);
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.score).reduce((a, b) => a + b) / scores.length;
  }

  /// Get highest score by game type
  int getHighestScore(GameType gameType) {
    final scores = getScoresByGameType(gameType);
    if (scores.isEmpty) return 0;
    return scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
  }
}
