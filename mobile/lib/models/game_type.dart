/// Enum representing the type of game
enum GameType {
  wordReplacement,
  rhyming,
}

/// Extension methods for GameType
extension GameTypeExtension on GameType {
  String get displayKey {
    switch (this) {
      case GameType.wordReplacement:
        return 'wordReplacement';
      case GameType.rhyming:
        return 'rhyming';
    }
  }

  String get descriptionKey {
    switch (this) {
      case GameType.wordReplacement:
        return 'wordReplacementDescription';
      case GameType.rhyming:
        return 'rhymingDescription';
    }
  }

  String get systemPromptContext {
    switch (this) {
      case GameType.wordReplacement:
        return '言葉の置き換え：意味が近く、かつ表現が豊かであるか。';
      case GameType.rhyming:
        return '韻を踏む：母音が一致しており、リズムが良いか。';
    }
  }
}
