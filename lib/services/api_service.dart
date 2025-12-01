import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../routes/app_routes.dart';
import 'storage_service.dart';

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

    // Auth interceptor - adds token to requests
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          if (!_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Retry original request
                final opts = error.requestOptions;
                final token = await StorageService.getAccessToken();
                opts.headers['Authorization'] = 'Bearer $token';
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
          }
        }
        handler.next(error);
      },
    ));
  }

  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio!.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await StorageService.saveAccessToken(data['accessToken']);
        await StorageService.saveRefreshToken(data['refreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
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

