import 'game_type.dart';

/// Model class representing a game score result
class GameScore {
  final String id;
  final GameType gameType;
  final String word;
  final List<String> answers;
  final int score;
  final String feedback;
  final int timeLimit;
  final DateTime playedAt;

  GameScore({
    required this.id,
    required this.gameType,
    required this.word,
    required this.answers,
    required this.score,
    required this.feedback,
    required this.timeLimit,
    required this.playedAt,
  });

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      id: json['id'] as String? ?? '',
      gameType: GameType.values.firstWhere(
        (e) => e.name == json['game_type'],
        orElse: () => GameType.wordReplacement,
      ),
      word: json['word'] as String? ?? '',
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      score: json['score'] as int? ?? 0,
      feedback: json['feedback'] as String? ?? '',
      timeLimit: json['time_limit'] as int? ?? 60,
      playedAt: DateTime.parse(
          json['played_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_type': gameType.name,
      'word': word,
      'answers': answers,
      'score': score,
      'feedback': feedback,
      'time_limit': timeLimit,
      'played_at': playedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'GameScore(id: $id, gameType: $gameType, word: $word, score: $score, playedAt: $playedAt)';
  }
}
