import 'dart:convert';

/// Utility class for JWT token operations
class JwtUtils {
  /// Decode JWT token payload without verification
  /// Returns null if token is invalid
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired
  /// Returns true if expired or invalid, false if valid
  static bool isTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;

    final payload = decodePayload(token);
    if (payload == null) return true;

    // Check for 'exp' claim (expiration time in seconds since epoch)
    final exp = payload['exp'];
    if (exp == null) return true;

    // Convert to DateTime
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();

    // Token is expired if expiration date is in the past
    // Add 30 second buffer to refresh before actual expiration
    return now.isAfter(expirationDate.subtract(const Duration(seconds: 30)));
  }

  /// Get token expiration date
  static DateTime? getExpirationDate(String? token) {
    if (token == null || token.isEmpty) return null;

    final payload = decodePayload(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// Get time until token expires (in seconds)
  /// Returns null if token is invalid or expired
  static int? getSecondsUntilExpiration(String? token) {
    final expirationDate = getExpirationDate(token);
    if (expirationDate == null) return null;

    final now = DateTime.now();
    if (now.isAfter(expirationDate)) return null;

    return expirationDate.difference(now).inSeconds;
  }

  /// Check if token will expire soon (within next 5 minutes)
  static bool willExpireSoon(String? token) {
    final secondsUntilExpiration = getSecondsUntilExpiration(token);
    if (secondsUntilExpiration == null) return true;

    // Consider "soon" as within 5 minutes
    return secondsUntilExpiration < 300; // 5 minutes
  }
}

