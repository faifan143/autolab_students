import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/session_model.dart';
import '../services/streaming_service.dart';

class StreamingProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  SessionModel? currentSession;
  bool isStreaming = false;
  bool isConnected = false;
  bool hasReceivedOffer = false;
  Map<String, dynamic>? streamOffer;
  String? connectionStatus;

  /// Load streaming status and initialize WebSocket connection
  Future<void> loadStreamingStatus(String sessionId) async {
    isLoading = true;
    error = null;
    connectionStatus = 'connecting'.tr;
    notifyListeners();

    try {
      // Load session status
      currentSession = await StreamingService.getSessionStreamingStatus(sessionId);
      isStreaming = currentSession?.isStreaming ?? false;

      // Initialize WebSocket connection for streaming
      if (isStreaming) {
        await _initializeStreamingConnection(sessionId);
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      connectionStatus = 'connection_error'.tr;
      notifyListeners();
    }
  }

  /// Initialize WebSocket connection and listen for streamOffer
  Future<void> _initializeStreamingConnection(String sessionId) async {
    try {
      // Set callback for stream offer
      StreamingService.setOnStreamOfferReceived((data) {
        if (data['type'] == 'streamEnd') {
          // Stream ended
          hasReceivedOffer = false;
          isConnected = false;
          connectionStatus = 'stream_ended'.tr;
          notifyListeners();
        } else {
          // Received stream offer
          _handleStreamOffer(data);
        }
      });

      // Initialize socket connection
      await StreamingService.initializeStreamingSocket(sessionId);
      
      connectionStatus = 'waiting_for_stream'.tr;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      connectionStatus = 'connection_error'.tr;
      notifyListeners();
    }
  }

  /// Handle incoming stream offer from teacher
  void _handleStreamOffer(Map<String, dynamic> offerData) {
    streamOffer = offerData;
    hasReceivedOffer = true;
    connectionStatus = 'receiving_stream'.tr;

    // Mock WebRTC answer creation
    // In a real implementation, this would create a proper WebRTC answer
    final mockAnswer = {
      'type': 'answer',
      'sdp': 'mock-sdp-answer-${DateTime.now().millisecondsSinceEpoch}',
      'sessionId': currentSession?.id,
    };

    // Send answer back to teacher
    StreamingService.sendStreamAnswer(mockAnswer);

    // Simulate connection establishment
    Future.delayed(const Duration(seconds: 1), () {
      isConnected = true;
      connectionStatus = 'stream_connected'.tr;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Manually reconnect to streaming
  Future<void> reconnect(String sessionId) async {
    hasReceivedOffer = false;
    isConnected = false;
    streamOffer = null;
    await loadStreamingStatus(sessionId);
  }

  @override
  void dispose() {
    StreamingService.disconnect();
    super.dispose();
  }
}


