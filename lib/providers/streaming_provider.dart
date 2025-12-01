import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../services/streaming_service.dart';

class StreamingProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  SessionModel? currentSession;
  bool isStreaming = false;

  Future<void> loadStreamingStatus(String sessionId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      currentSession = await StreamingService.getSessionStreamingStatus(sessionId);
      isStreaming = currentSession?.isStreaming ?? false;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  // TODO: Future WebRTC integration
  // - Initialize viewer connection
  // - Handle video stream
  // - Display live feed
}


