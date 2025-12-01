import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing secure and shared storage
class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyServerIp = 'server_ip';
  static const String _keyServerPort = 'server_port';

  // Secure storage (tokens)
  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _keyAccessToken, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  // Shared preferences (server IP/port)
  static Future<void> saveServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerIp, ip);
  }

  static Future<String?> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerIp);
  }

  static Future<void> saveServerPort(String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerPort, port);
  }

  static Future<String?> getServerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerPort);
  }

  static Future<void> clearServerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerIp);
    await prefs.remove(_keyServerPort);
  }

  static Future<String> getBaseUrl() async {
    final ip = await getServerIp() ?? '192.168.0.11';
    final port = await getServerPort() ?? '3000';
    return 'http://$ip:$port';
  }
}
