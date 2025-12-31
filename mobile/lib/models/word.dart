/// Model class representing a word of the day
class Word {
  final String id;
  final String word;
  final String reading;
  final String meaning;
  final String example;
  final DateTime date;

  Word({
    required this.id,
    required this.word,
    required this.reading,
    required this.meaning,
    required this.example,
    required this.date,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      example: json['example'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'reading': reading,
      'meaning': meaning,
      'example': example,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Word(id: $id, word: $word, reading: $reading, meaning: $meaning, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Word &&
        other.id == id &&
        other.word == word &&
        other.reading == reading &&
        other.meaning == meaning &&
        other.example == example &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        word.hashCode ^
        reading.hashCode ^
        meaning.hashCode ^
        example.hashCode ^
        date.hashCode;
  }
}
