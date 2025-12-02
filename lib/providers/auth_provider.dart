import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../utils/jwt_utils.dart';
import '../services/firebase_notifications_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  UserModel? currentUser;
  bool isAuthenticated = false;
  bool isTokenExpired = false;

  /// Check authentication status on app startup
  Future<bool> checkAuthenticationStatus() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Check if tokens exist
      final accessToken = await StorageService.getAccessToken();
      final refreshToken = await StorageService.getRefreshToken();

      if (accessToken == null || refreshToken == null) {
        isAuthenticated = false;
        isTokenExpired = false;
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if access token is expired
      if (JwtUtils.isTokenExpired(accessToken)) {
        // Try to refresh token
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          isAuthenticated = true;
          isTokenExpired = false;
          // Try to load current user
          await loadCurrentUser();
        } else {
          // Refresh failed - check if refresh token is also expired
          if (JwtUtils.isTokenExpired(refreshToken)) {
            isTokenExpired = true;
            isAuthenticated = false;
            await AuthService.logout();
          } else {
            isAuthenticated = false;
            isTokenExpired = true;
          }
        }
      } else {
        // Access token is valid
        isAuthenticated = true;
        isTokenExpired = false;
        // Try to load current user
        await loadCurrentUser();
      }

      isLoading = false;
      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      error = e.toString();
      isAuthenticated = false;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Validate and refresh token if needed
  Future<bool> validateAndRefreshToken() async {
    try {
      final refreshed = await AuthService.validateAndRefreshToken();
      if (refreshed) {
        isAuthenticated = true;
        isTokenExpired = false;
        notifyListeners();
        return true;
      } else {
        isAuthenticated = false;
        isTokenExpired = true;
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = e.toString();
      isAuthenticated = false;
      isTokenExpired = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final authResponse = await AuthService.login(
        email: email,
        password: password,
      );
      currentUser = authResponse.user;
      isAuthenticated = true;
      isTokenExpired = false;
      isLoading = false;
      notifyListeners();
      
      // Register FCM token after successful login
      try {
        final fcmToken = await FirebaseNotificationsService.getToken();
        if (fcmToken != null) {
          await FirebaseNotificationsService.registerFCMToken(fcmToken);
        }
      } catch (e) {
        // Don't fail login if FCM registration fails
        print('FCM token registration failed: $e');
      }
      
      return true;
    } catch (e) {
      error = e.toString();
      isAuthenticated = false;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final authResponse = await AuthService.register(
        name: name,
        email: email,
        password: password,
      );
      currentUser = authResponse.user;
      isAuthenticated = true;
      isTokenExpired = false;
      isLoading = false;
      notifyListeners();
      
      // Register FCM token after successful registration
      try {
        final fcmToken = await FirebaseNotificationsService.getToken();
        if (fcmToken != null) {
          await FirebaseNotificationsService.registerFCMToken(fcmToken);
        }
      } catch (e) {
        // Don't fail registration if FCM registration fails
        print('FCM token registration failed: $e');
      }
      
      return true;
    } catch (e) {
      error = e.toString();
      isAuthenticated = false;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    currentUser = null;
    isAuthenticated = false;
    isTokenExpired = false;
    notifyListeners();
    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> loadCurrentUser() async {
    currentUser = await AuthService.getCurrentUser();
    notifyListeners();
  }
}


