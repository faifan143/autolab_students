import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

/// Comprehensive HTTP request/response logger
/// Separates API logs from Flutter's normal output with distinct formatting
class LoggerService {
  static const String _separator =
      '═══════════════════════════════════════════════════════════';
  static const String _subSeparator =
      '───────────────────────────────────────────────────────────';

  /// Log HTTP request
  static void logRequest(RequestOptions options) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());

    print('\n$_separator');
    print('🌐 HTTP REQUEST [$timestamp]');
    print(_subSeparator);
    print('📍 Method: ${options.method}');
    print('🔗 URL: ${options.uri}');

    // Log headers (excluding sensitive data)
    if (options.headers.isNotEmpty) {
      print('📋 Headers:');
      options.headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          // Mask token for security
          final token = value.toString();
          if (token.startsWith('Bearer ')) {
            final masked =
                'Bearer ${token.substring(7, 15)}...${token.substring(token.length - 4)}';
            print('   $key: $masked');
          } else {
            print('   $key: [REDACTED]');
          }
        } else {
          print('   $key: $value');
        }
      });
    }

    // Log query parameters
    if (options.queryParameters.isNotEmpty) {
      print('🔍 Query Parameters:');
      options.queryParameters.forEach((key, value) {
        print('   $key: $value');
      });
    }

    // Log request body
    if (options.data != null) {
      print('📦 Request Body:');
      try {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          print('   [FormData with ${formData.fields.length} fields]');
          for (var field in formData.fields) {
            print('   ${field.key}: ${field.value}');
          }
        } else if (options.data is Map || options.data is List) {
          final jsonString = const JsonEncoder.withIndent(
            '   ',
          ).convert(options.data);
          print(jsonString);
        } else {
          print('   ${options.data}');
        }
      } catch (e) {
        print('   [Unable to serialize body: $e]');
        print('   ${options.data}');
      }
    }

    print(_separator);
  }

  /// Log HTTP response
  static void logResponse(Response response) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final duration = response.extra['duration'] ?? 'N/A';

    print('\n$_separator');
    print('✅ HTTP RESPONSE [$timestamp] (${duration}ms)');
    print(_subSeparator);
    print('📍 URL: ${response.requestOptions.uri}');
    print(
      '📊 Status: ${response.statusCode} ${_getStatusText(response.statusCode)}',
    );

    // Log response headers
    if (response.headers.map.isNotEmpty) {
      print('📋 Response Headers:');
      response.headers.map.forEach((key, values) {
        print('   $key: ${values.join(", ")}');
      });
    }

    // Log response data
    if (response.data != null) {
      print('📦 Response Body:');
      try {
        if (response.data is String) {
          // Try to parse as JSON for pretty printing
          try {
            final jsonData = json.decode(response.data);
            final jsonString = const JsonEncoder.withIndent(
              '   ',
            ).convert(jsonData);
            print(jsonString);
          } catch (_) {
            // Not JSON, print as string
            print('   ${response.data}');
          }
        } else if (response.data is Map || response.data is List) {
          final jsonString = const JsonEncoder.withIndent(
            '   ',
          ).convert(response.data);
          print(jsonString);
        } else {
          print('   ${response.data}');
        }
      } catch (e) {
        print('   [Unable to serialize response: $e]');
        print('   ${response.data}');
      }
    }

    print(_separator);
  }

  /// Log HTTP error
  static void logError(DioException error) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());

    print('\n$_separator');
    print('❌ HTTP ERROR [$timestamp]');
    print(_subSeparator);
    print('📍 URL: ${error.requestOptions.uri}');
    print('📍 Method: ${error.requestOptions.method}');

    if (error.response != null) {
      print(
        '📊 Status: ${error.response!.statusCode} ${_getStatusText(error.response!.statusCode)}',
      );

      // Log error response headers
      if (error.response!.headers.map.isNotEmpty) {
        print('📋 Response Headers:');
        error.response!.headers.map.forEach((key, values) {
          print('   $key: ${values.join(", ")}');
        });
      }

      // Log error response data
      if (error.response!.data != null) {
        print('📦 Error Response Body:');
        try {
          if (error.response!.data is String) {
            try {
              final jsonData = json.decode(error.response!.data);
              final jsonString = const JsonEncoder.withIndent(
                '   ',
              ).convert(jsonData);
              print(jsonString);
            } catch (_) {
              print('   ${error.response!.data}');
            }
          } else if (error.response!.data is Map ||
              error.response!.data is List) {
            final jsonString = const JsonEncoder.withIndent(
              '   ',
            ).convert(error.response!.data);
            print(jsonString);
          } else {
            print('   ${error.response!.data}');
          }
        } catch (e) {
          print('   [Unable to serialize error response: $e]');
          print('   ${error.response!.data}');
        }
      }
    } else {
      print('📊 Error Type: ${error.type}');
      print('💬 Error Message: ${error.message}');
    }

    // Log request details if available
    if (error.requestOptions.data != null) {
      print('📦 Request Body:');
      try {
        if (error.requestOptions.data is FormData) {
          print('   [FormData]');
        } else if (error.requestOptions.data is Map ||
            error.requestOptions.data is List) {
          final jsonString = const JsonEncoder.withIndent(
            '   ',
          ).convert(error.requestOptions.data);
          print(jsonString);
        } else {
          print('   ${error.requestOptions.data}');
        }
      } catch (e) {
        print('   [Unable to serialize request body: $e]');
      }
    }

    print(_separator);
  }

  /// Log token refresh attempt
  static void logTokenRefresh({required bool success, String? error}) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());

    print('\n$_separator');
    print('🔄 TOKEN REFRESH [$timestamp]');
    print(_subSeparator);
    if (success) {
      print('✅ Token refresh successful');
    } else {
      print('❌ Token refresh failed');
      if (error != null) {
        print('💬 Error: $error');
      }
    }
    print(_separator);
  }

  /// Get status text for HTTP status code
  static String _getStatusText(int? statusCode) {
    if (statusCode == null) return 'Unknown';

    switch (statusCode) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'Status $statusCode';
    }
  }

  /// Log general info message
  static void logInfo(String message) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    print('\n[$timestamp] ℹ️  INFO: $message');
  }

  /// Log warning message
  static void logWarning(String message) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    print('\n[$timestamp] ⚠️  WARNING: $message');
  }
}
