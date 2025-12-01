import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';

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

