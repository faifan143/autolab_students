import '../models/session_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class SessionsService {
  /// Get all sessions for a lab
  static Future<List<SessionModel>> getLabSessions(String labId) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.labSessions(labId));
    
    final List<dynamic> data = response.data;
    return data.map((json) => SessionModel.fromJson(json)).toList();
  }

  /// Get a specific session by ID
  static Future<SessionModel> getSession(String sessionId) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.session(sessionId));
    
    return SessionModel.fromJson(response.data);
  }
}

