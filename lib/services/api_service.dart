import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/jwt_utils.dart';
import 'logger_service.dart';

/// Core API service with Dio, token refresh, and 401 auto-logout
class ApiService {
  static Dio? _dio;
  static bool _isRefreshing = false;

  static Future<Dio> get dio async {
    if (_dio == null) {
      await _initializeDio();
    }
    return _dio!;
  }

  static Future<void> _initializeDio() async {
    final baseUrl = await StorageService.getBaseUrl();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request/Response logging interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          LoggerService.logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Calculate request duration
          final startTime =
              response.requestOptions.extra['startTime'] as DateTime?;
          if (startTime != null) {
            final duration = DateTime.now()
                .difference(startTime)
                .inMilliseconds;
            response.extra['duration'] = duration;
          }
          LoggerService.logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) {
          LoggerService.logError(error);
          handler.next(error);
        },
      ),
    );

    // Auth interceptor - validates token and adds to requests
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Track request start time for duration calculation
          options.extra['startTime'] = DateTime.now();

          // Skip token validation for refresh endpoint to avoid recursion
          // Check both path and full URI to handle different base URL configurations
          final isRefreshEndpoint =
              options.path == ApiEndpoints.refresh ||
              options.path.endsWith(ApiEndpoints.refresh) ||
              options.uri.path.endsWith(ApiEndpoints.refresh);

          if (isRefreshEndpoint) {
            handler.next(options);
            return;
          }

          // Check and refresh token before making request if needed
          final accessToken = await StorageService.getAccessToken();
          if (accessToken != null) {
            // Check if token is expired or will expire soon
            if (JwtUtils.isTokenExpired(accessToken) ||
                JwtUtils.willExpireSoon(accessToken)) {
              // Try to refresh token before making the request
              if (!_isRefreshing) {
                _isRefreshing = true;
                try {
                  final refreshed = await AuthService.refreshAccessToken();
                  if (!refreshed) {
                    // Refresh failed - logout
                    _isRefreshing = false;
                    LoggerService.logWarning(
                      'Token refresh failed, logging out user',
                    );
                    await _logout();
                    return handler.reject(
                      DioException(
                        requestOptions: options,
                        error: 'Token refresh failed',
                      ),
                    );
                  }
                } catch (e) {
                  _isRefreshing = false;
                  LoggerService.logWarning(
                    'Token refresh error: $e, logging out user',
                  );
                  await _logout();
                  return handler.reject(
                    DioException(
                      requestOptions: options,
                      error: 'Token refresh error: $e',
                    ),
                  );
                }
                _isRefreshing = false;
              } else {
                // Already refreshing, wait for it to complete
                LoggerService.logInfo(
                  'Token refresh already in progress, waiting...',
                );
                int waitCount = 0;
                while (_isRefreshing && waitCount < 20) {
                  await Future.delayed(const Duration(milliseconds: 100));
                  waitCount++;
                }
              }
            }

            // Get the (possibly refreshed) token
            final token = await StorageService.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Skip refresh logic for refresh endpoint to avoid recursion
          final isRefreshEndpoint =
              error.requestOptions.path == ApiEndpoints.refresh ||
              error.requestOptions.path.endsWith(ApiEndpoints.refresh) ||
              error.requestOptions.uri.path.endsWith(ApiEndpoints.refresh);

          if (error.response?.statusCode == 401 && !isRefreshEndpoint) {
            // Try to refresh token on 401 error
            if (!_isRefreshing) {
              _isRefreshing = true;
              LoggerService.logInfo(
                'Received 401, attempting token refresh...',
              );
              try {
                final refreshed = await AuthService.refreshAccessToken();
                if (refreshed) {
                  // Retry original request with new token
                  final opts = error.requestOptions;
                  final token = await StorageService.getAccessToken();
                  if (token != null) {
                    opts.headers['Authorization'] = 'Bearer $token';
                  }
                  // Mark this as a retry to prevent infinite loops
                  opts.extra['isRetry'] = true;
                  LoggerService.logInfo(
                    'Retrying original request after successful token refresh',
                  );
                  try {
                    final response = await _dio!.fetch(opts);
                    _isRefreshing = false;
                    return handler.resolve(response);
                  } catch (retryError) {
                    // If retry also fails, log and continue with error
                    LoggerService.logWarning(
                      'Retry after token refresh also failed: $retryError',
                    );
                    _isRefreshing = false;
                    return handler.next(error);
                  }
                } else {
                  // Refresh failed - logout
                  LoggerService.logWarning(
                    'Token refresh failed on 401, logging out user',
                  );
                  await _logout();
                  _isRefreshing = false;
                  return handler.next(error);
                }
              } catch (e) {
                LoggerService.logWarning(
                  'Token refresh error on 401: $e, logging out user',
                );
                await _logout();
                _isRefreshing = false;
                return handler.next(error);
              }
            } else {
              // Already refreshing, wait a bit and retry
              LoggerService.logInfo(
                'Token refresh in progress, waiting before retry...',
              );
              int waitCount = 0;
              while (_isRefreshing && waitCount < 10) {
                await Future.delayed(const Duration(milliseconds: 200));
                waitCount++;
              }
              final token = await StorageService.getAccessToken();
              if (token != null) {
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $token';
                try {
                  LoggerService.logInfo(
                    'Retrying request after waiting for token refresh',
                  );
                  final response = await _dio!.fetch(opts);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static Future<void> _logout() async {
    await StorageService.clearTokens();
    // Navigate to login
    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Reinitialize Dio with new base URL (after IP config change)
  static Future<void> reinitialize() async {
    _dio = null;
    await _initializeDio();
  }
}
