import '../models/session_model.dart';
import 'sessions_service.dart';

/// Streaming session REST helpers. Live WebRTC SFU signaling lives in
/// [WebRTCService] (`/ws/streaming`).
class StreamingService {
  /// Get session streaming status
  static Future<SessionModel> getSessionStreamingStatus(String sessionId) async {
    return await SessionsService.getSession(sessionId);
  }

  /// No separate REST socket; kept for call-site cleanup compatibility.
  static void disconnect() {}

  static bool get isConnected => false;
}
