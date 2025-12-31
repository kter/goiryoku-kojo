import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/models.dart';

/// Result from AI scoring
class ScoringResult {
  final int score;
  final String feedback;

  ScoringResult({
    required this.score,
    required this.feedback,
  });

  factory ScoringResult.fromJson(Map<String, dynamic> json) {
    return ScoringResult(
      score: json['score'] as int? ?? 0,
      feedback: json['feedback'] as String? ?? '',
    );
  }
}

/// Service for AI-powered scoring using Gemini 1.5 Flash
class ScoringService {
  static const String _modelName = 'gemini-1.5-flash';

  late final GenerativeModel _model;

  ScoringService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Score user's answers for a given word and game type
  Future<ScoringResult> scoreAnswers({
    required String word,
    required List<String> answers,
    required GameType gameType,
  }) async {
    final systemPrompt = _buildSystemPrompt(gameType);
    final userPrompt = _buildUserPrompt(word, answers, gameType);

    try {
      final chat = _model.startChat(history: [
        Content.text(systemPrompt),
      ]);

      final response = await chat.sendMessage(Content.text(userPrompt));
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return ScoringResult(
          score: 0,
          feedback: 'AIからの応答を受け取れませんでした。',
        );
      }

      // Parse JSON response
      try {
        final jsonResponse = json.decode(responseText) as Map<String, dynamic>;
        return ScoringResult.fromJson(jsonResponse);
      } catch (e) {
        // If JSON parsing fails, try to extract score and feedback from text
        return ScoringResult(
          score: 0,
          feedback: responseText,
        );
      }
    } catch (e) {
      return ScoringResult(
        score: 0,
        feedback: 'スコアリング中にエラーが発生しました: $e',
      );
    }
  }

  String _buildSystemPrompt(GameType gameType) {
    final gameContext = gameType.systemPromptContext;

    return '''あなたは言語学の専門家です。提示された『お題』に対して、ユーザーが入力した『単語リスト』を以下の基準で採点し、JSON形式で返してください。

評価基準：
$gameContext

回答形式（必ずこの形式のJSONで返してください）：
{
  "score": <0-100の整数>,
  "feedback": "<採点理由と改善点を含む日本語のフィードバック>"
}

採点のポイント：
- 各単語は最大10点
- 最大10単語まで採点（100点満点）
- 重複した単語は採点しない
- 不適切または無関係な単語は0点
- 創造性と語彙力の豊かさを評価''';
  }

  String _buildUserPrompt(String word, List<String> answers, GameType gameType) {
    final gameTypeName = gameType == GameType.wordReplacement
        ? '言葉の置き換え'
        : '韻を踏む';

    final answersText = answers.isEmpty
        ? '（回答なし）'
        : answers.map((a) => '・$a').join('\n');

    return '''【ゲーム種別】$gameTypeName

【お題】$word

【ユーザーの回答】
$answersText

上記の回答を採点してください。''';
  }
}
