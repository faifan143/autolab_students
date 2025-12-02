import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/session_model.dart';
import '../services/streaming_service.dart';
import '../services/webrtc_service.dart';

class StreamingProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  SessionModel? currentSession;
  bool isStreaming = false;
  bool isConnected = false;
  bool hasReceivedOffer = false;
  Map<String, dynamic>? streamOffer;
  String? connectionStatus;
  RTCVideoRenderer? remoteRenderer;

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
      // Initialize WebRTC peer connection
      await WebRTCService.initializePeerConnection();

      // Initialize video renderer
      remoteRenderer = await WebRTCService.initializeRenderer();

      // Set callbacks
      WebRTCService.setOnRemoteStreamReady((renderer) {
        remoteRenderer = renderer;
        hasReceivedOffer = true;
        isConnected = true;
        connectionStatus = 'stream_connected'.tr;
        notifyListeners();
      });

      WebRTCService.setOnConnectionStateChanged((state) {
        connectionStatus = state;
        isConnected = state == 'RTCPeerConnectionStateConnected';
        notifyListeners();
      });

      WebRTCService.setOnError((errorMsg) {
        error = errorMsg;
        connectionStatus = 'connection_error'.tr;
        notifyListeners();
      });

      // Initialize WebSocket signaling
      await WebRTCService.initializeSignaling(sessionId);

      connectionStatus = 'waiting_for_stream'.tr;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      connectionStatus = 'connection_error'.tr;
      notifyListeners();
    }
  }

  /// Manually reconnect to streaming
  Future<void> reconnect(String sessionId) async {
    await WebRTCService.disconnect();
    hasReceivedOffer = false;
    isConnected = false;
    streamOffer = null;
    remoteRenderer = null;
    await loadStreamingStatus(sessionId);
  }

  @override
  void dispose() {
    WebRTCService.disconnect();
    StreamingService.disconnect();
    super.dispose();
  }
}


