import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/jwt_utils.dart';

class AuthService {
  /// Login with email and password
  static Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final dio = await ApiService.dio;
    final response = await dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
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
        return false;
      }

      // Check if refresh token is expired
      if (JwtUtils.isTokenExpired(refreshToken)) {
        return false;
      }

      // Create a temporary Dio instance without interceptors to avoid recursion
      final baseUrl = await StorageService.getBaseUrl();
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ));

      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await StorageService.saveAccessToken(data['accessToken']);
        
        // Update refresh token if provided, otherwise keep the old one
        if (data['refreshToken'] != null) {
          await StorageService.saveRefreshToken(data['refreshToken']);
        }
        
        return true;
      }
      return false;
    } catch (e) {
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

  /// Get current user from storage (if available)
  static Future<UserModel?> getCurrentUser() async {
    final token = await StorageService.getAccessToken();
    return token != null ? UserModel(id: '', name: '', email: '', role: 'student') : null;
  }

  /// Logout - clear tokens
  static Future<void> logout() async {
    await StorageService.clearTokens();
  }
}

