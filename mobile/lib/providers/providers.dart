import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/services.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for WordCacheRepository
final wordCacheRepositoryProvider = Provider<WordCacheRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WordCacheRepository(prefs);
});

/// Provider for ScoreRepository
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ScoreRepository(prefs);
});

/// Provider for WordApiClient
final wordApiClientProvider = Provider<WordApiClient>((ref) {
  return WordApiClient();
});

/// Provider for ScoringService
final scoringServiceProvider = Provider<ScoringService>((ref) {
  return ScoringService();
});

/// Provider for today's word with automatic fetching/caching logic
final todaysWordProvider = FutureProvider<Word?>((ref) async {
  final cache = ref.watch(wordCacheRepositoryProvider);
  final api = ref.watch(wordApiClientProvider);

  // Check if cache is valid
  if (cache.isCacheValid()) {
    final todaysWord = cache.getTodaysWord();
    // Also check if wordEn is populated - if not, we need to refetch
    if (todaysWord != null && todaysWord.wordEn.isNotEmpty) {
      return todaysWord;
    }
    // wordEn is empty, clear cache to force refetch
    if (todaysWord != null && todaysWord.wordEn.isEmpty) {
      await cache.clearCache();
    }
  }

  // Fetch from API if cache is invalid or word not found
  try {
    final response = await api.fetchWords();
    await cache.saveWords(response.words, response.endDate);
    return cache.getTodaysWord();
  } catch (e) {
    // If API fails, try to get from cache anyway
    final cachedWord = cache.getTodaysWord();
    if (cachedWord != null) {
      return cachedWord;
    }
    rethrow;
  }
});

/// Provider for all game scores
final allScoresProvider = Provider<List<GameScore>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getAllScores();
});

/// Provider for scores by game type
final scoresByGameTypeProvider =
    Provider.family<List<GameScore>, GameType>((ref, gameType) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getScoresByGameType(gameType);
});

/// Provider for recent scores (last 30 days)
final recentScoresProvider = Provider<List<GameScore>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return repository.getRecentScores(days: 30);
});

/// State notifier for managing score updates
class ScoreNotifier extends StateNotifier<List<GameScore>> {
  final ScoreRepository _repository;

  ScoreNotifier(this._repository) : super(_repository.getAllScores());

  Future<void> addScore(GameScore score) async {
    await _repository.saveScore(score);
    state = _repository.getAllScores();
  }

  Future<void> clearAll() async {
    await _repository.clearScores();
    state = [];
  }
}

/// Provider for ScoreNotifier
final scoreNotifierProvider =
    StateNotifierProvider<ScoreNotifier, List<GameScore>>((ref) {
  final repository = ref.watch(scoreRepositoryProvider);
  return ScoreNotifier(repository);
});
