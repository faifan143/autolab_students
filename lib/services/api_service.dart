import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/jwt_utils.dart';

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
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Auth interceptor - validates token and adds to requests
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip token validation for refresh endpoint to avoid recursion
        if (options.path == ApiEndpoints.refresh) {
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
                await _logout();
                return handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'Token refresh error: $e',
                  ),
                );
              }
              _isRefreshing = false;
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
        if (error.response?.statusCode == 401) {
          // Try to refresh token on 401 error
          if (!_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await AuthService.refreshAccessToken();
              if (refreshed) {
                // Retry original request with new token
                final opts = error.requestOptions;
                final token = await StorageService.getAccessToken();
                if (token != null) {
                  opts.headers['Authorization'] = 'Bearer $token';
                }
                final response = await _dio!.fetch(opts);
                _isRefreshing = false;
                return handler.resolve(response);
              } else {
                // Refresh failed - logout
                await _logout();
                _isRefreshing = false;
                return handler.next(error);
              }
            } catch (e) {
              await _logout();
              _isRefreshing = false;
              return handler.next(error);
            }
          } else {
            // Already refreshing, wait a bit and retry
            await Future.delayed(const Duration(milliseconds: 500));
            final token = await StorageService.getAccessToken();
            if (token != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              try {
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
    ));
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

