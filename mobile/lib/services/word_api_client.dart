import 'package:dio/dio.dart';
import '../models/models.dart';

/// API client for fetching word of the day data
class WordApiClient {
  static const String _baseUrl = 'https://api.word-of-the-day.devtools.site';
  static const int _defaultDays = 30;

  final Dio _dio;

  WordApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Fetch words for the next N days
  Future<WordListResponse> fetchWords({int days = _defaultDays}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/word',
        queryParameters: {'days': days},
      );

      if (response.data != null) {
        return WordListResponse.fromJson(response.data!);
      }

      throw Exception('Empty response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch word for a specific date
  Future<Word> fetchWordForDate(DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/word/$dateStr',
      );

      if (response.data != null) {
        return Word.fromJson(response.data!);
      }

      throw Exception('Empty response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return Exception('Word not found for the requested date.');
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later.');
        }
        return Exception('Server error: $statusCode');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
