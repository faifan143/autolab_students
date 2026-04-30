import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/jwt_utils.dart';
import 'logger_service.dart';

class AuthService {
  /// Login with email and password
  static Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final dio = await ApiService.dio;
    final response = await dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final authResponse = AuthResponseModel.fromJson(response.data);

    // Save tokens
    await StorageService.saveAccessToken(authResponse.accessToken);
    await StorageService.saveRefreshToken(authResponse.refreshToken);

    return authResponse;
  }

  /// Register new student account
  static Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final dio = await ApiService.dio;
    final response = await dio.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'student', // Hardcoded as per requirements
      },
    );

    final authResponse = AuthResponseModel.fromJson(response.data);

    // Save tokens
    await StorageService.saveAccessToken(authResponse.accessToken);
    await StorageService.saveRefreshToken(authResponse.refreshToken);

    return authResponse;
  }

  /// Refresh access token using refresh token
  /// Returns true if refresh was successful, false otherwise
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        LoggerService.logTokenRefresh(
          success: false,
          error: 'No refresh token found',
        );
        return false;
      }

      // Check if refresh token is expired
      if (JwtUtils.isTokenExpired(refreshToken)) {
        LoggerService.logTokenRefresh(
          success: false,
          error: 'Refresh token is expired',
        );
        return false;
      }

      // Create a temporary Dio instance without interceptors to avoid recursion
      final baseUrl = await StorageService.getBaseUrl();
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Log the refresh request
      LoggerService.logInfo('Attempting to refresh access token...');

      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      // Accept both 200 (OK) and 201 (Created) as success status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Validate response structure
        if (data is! Map || !data.containsKey('accessToken')) {
          LoggerService.logTokenRefresh(
            success: false,
            error: 'Invalid response structure: missing accessToken',
          );
          return false;
        }

        await StorageService.saveAccessToken(data['accessToken']);

        // Update refresh token if provided, otherwise keep the old one
        if (data['refreshToken'] != null) {
          await StorageService.saveRefreshToken(data['refreshToken']);
        }

        LoggerService.logTokenRefresh(success: true);
        return true;
      }

      LoggerService.logTokenRefresh(
        success: false,
        error: 'Unexpected status code: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      LoggerService.logTokenRefresh(success: false, error: e.toString());
      return false;
    }
  }

  /// Check if user is authenticated (has valid tokens)
  static Future<bool> isAuthenticated() async {
    final accessToken = await StorageService.getAccessToken();
    final refreshToken = await StorageService.getRefreshToken();

    // Must have both tokens
    if (accessToken == null || refreshToken == null) {
      return false;
    }

    // If access token is valid, user is authenticated
    if (!JwtUtils.isTokenExpired(accessToken)) {
      return true;
    }

    // If access token is expired but refresh token is valid, try to refresh
    if (!JwtUtils.isTokenExpired(refreshToken)) {
      final refreshed = await refreshAccessToken();
      return refreshed;
    }

    // Both tokens are expired or invalid
    return false;
  }

  /// Validate and refresh token if needed
  /// Returns true if token is valid or was successfully refreshed
  static Future<bool> validateAndRefreshToken() async {
    final accessToken = await StorageService.getAccessToken();

    if (accessToken == null) {
      return false;
    }

    // If token is not expired, it's valid
    if (!JwtUtils.isTokenExpired(accessToken)) {
      return true;
    }

    // Token is expired, try to refresh
    return await refreshAccessToken();
  }

  /// Get current user from JWT token and API
  static Future<UserModel?> getCurrentUser() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) return null;

      // Decode JWT token to extract user ID
      final payload = JwtUtils.decodePayload(token);
      if (payload == null) return null;

      // Extract user ID from token payload (sub claim)
      final userId = payload['sub'] ?? payload['userId'] ?? payload['id'];
      if (userId == null || userId.toString().isEmpty) {
        return null;
      }

      // Fetch full user data from API using the user ID
      try {
        final dio = await ApiService.dio;
        final response = await dio.get(ApiEndpoints.user(userId.toString()));
        
        if (response.statusCode == 200 && response.data != null) {
          return UserModel.fromJson(response.data);
        }
      } catch (e) {
        LoggerService.logInfo('Failed to fetch user from API: $e');
        // Fallback: return user with ID and role from token
        final role = payload['role'] ?? 'student';
        return UserModel(
          id: userId.toString(),
          name: '', // Will be empty, but at least we have the ID
          email: '',
          role: role.toString(),
        );
      }

      return null;
    } catch (e) {
      LoggerService.logInfo('Failed to get current user: $e');
      return null;
    }
  }

  /// Logout - clear tokens
  static Future<void> logout() async {
    await StorageService.clearTokens();
  }
}
