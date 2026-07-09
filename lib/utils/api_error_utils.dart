import 'package:dio/dio.dart';

/// Extracts a short, user-facing message from API failures.
class ApiErrorUtils {
  static String message(Object error, {String fallback = 'Request failed'}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        if (msg is List && msg.isNotEmpty) {
          return msg.map((e) => e.toString()).join('\n');
        }
      }
      if (data is String && data.trim().isNotEmpty) return data.trim();

      final status = error.response?.statusCode;
      if (status == 403) {
        return 'You cannot do this right now (forbidden).';
      }
      if (status == 401) {
        return 'Please sign in again.';
      }
      if (status == 404) {
        return 'Not found.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Cannot reach the server. Check the Server IP and that the backend is running.';
      }
    }

    final text = error.toString();
    if (text.length > 180) {
      return fallback;
    }
    return text.isEmpty ? fallback : text;
  }
}
