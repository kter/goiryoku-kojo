import 'word.dart';

/// API response containing a list of words for multiple days
class WordListResponse {
  final List<Word> words;
  final DateTime startDate;
  final DateTime endDate;

  WordListResponse({
    required this.words,
    required this.startDate,
    required this.endDate,
  });

  factory WordListResponse.fromJson(Map<String, dynamic> json) {
    final wordsList = (json['words'] as List<dynamic>?)
            ?.map((e) => Word.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return WordListResponse(
      words: wordsList,
      startDate: DateTime.parse(
          json['start_date'] as String? ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(
          json['end_date'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'words': words.map((w) => w.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}
