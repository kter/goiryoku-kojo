import 'dart:convert';
import 'package:dio/dio.dart';
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

/// Service for AI-powered scoring via backend API
class ScoringService {
  static const String _baseUrl = 'https://score-answers-cqiy6alq3a-an.a.run.app';

  final Dio _dio;

  ScoringService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// Score user's answers for a given word and game type
  Future<ScoringResult> scoreAnswers({
    required String word,
    required List<String> answers,
    required GameType gameType,
    String locale = 'ja',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/',
        data: {
          'word': word,
          'answers': answers,
          'game_type': gameType == GameType.wordReplacement
              ? 'word_replacement'
              : 'rhyming',
          'locale': locale,
        },
      );

      if (response.data != null && response.data!['success'] == true) {
        return ScoringResult.fromJson(response.data!);
      }

      final errorMessage = response.data?['error'] ?? 'Unknown error';
      final feedbackMessage = locale == 'en' 
          ? 'Error occurred during scoring: $errorMessage'
          : 'スコアリング中にエラーが発生しました: $errorMessage';
      return ScoringResult(
        score: 0,
        feedback: feedbackMessage,
      );
    } on DioException catch (e) {
      final feedbackMessage = locale == 'en'
          ? 'Error occurred during scoring: ${_handleDioError(e, locale)}'
          : 'スコアリング中にエラーが発生しました: ${_handleDioError(e, locale)}';
      return ScoringResult(
        score: 0,
        feedback: feedbackMessage,
      );
    } catch (e) {
      final feedbackMessage = locale == 'en'
          ? 'Error occurred during scoring: $e'
          : 'スコアリング中にエラーが発生しました: $e';
      return ScoringResult(
        score: 0,
        feedback: feedbackMessage,
      );
    }
  }

  String _handleDioError(DioException e, String locale) {
    final isEnglish = locale == 'en';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return isEnglish 
            ? 'Connection timed out. Please check your internet connection.'
            : '接続がタイムアウトしました。インターネット接続を確認してください。';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 500) {
          return isEnglish
              ? 'Server error occurred. Please try again later.'
              : 'サーバーエラーが発生しました。しばらくしてから再度お試しください。';
        }
        return isEnglish 
            ? 'Server error: $statusCode'
            : 'サーバーエラー: $statusCode';
      case DioExceptionType.cancel:
        return isEnglish
            ? 'Request was cancelled.'
            : 'リクエストがキャンセルされました。';
      default:
        return isEnglish
            ? 'Network error: ${e.message}'
            : 'ネットワークエラー: ${e.message}';
    }
  }
}
