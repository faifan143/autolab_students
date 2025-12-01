import '../models/session_model.dart';
import 'sessions_service.dart';

/// Streaming service - scaffold only for future WebRTC integration
class StreamingService {
  /// Get session streaming status
  static Future<SessionModel> getSessionStreamingStatus(String sessionId) async {
    // For now, just return the session which contains isStreaming flag
    return await SessionsService.getSession(sessionId);
  }

  // TODO: Future WebRTC integration with Mediasoup
  // - Initialize WebRTC connection
  // - Handle video/audio streams
  // - Display live stream in viewer mode
}

