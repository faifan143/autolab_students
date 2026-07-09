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
  bool _initializedForSession = false;
  String? _activeSessionId;

  /// Load streaming status and initialize WebSocket connection
  Future<void> loadStreamingStatus(String sessionId) async {
    isLoading = true;
    error = null;
    connectionStatus = 'connecting'.tr;
    _activeSessionId = sessionId;
    notifyListeners();

    try {
      currentSession =
          await StreamingService.getSessionStreamingStatus(sessionId);
      isStreaming = currentSession?.isStreaming ?? false;

      if (isStreaming) {
        await _initializeStreamingConnection(sessionId);
      } else {
        connectionStatus = 'waiting_for_stream'.tr;
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

  /// Initialize mediasoup SFU consumer against `/ws/streaming`
  Future<void> _initializeStreamingConnection(String sessionId) async {
    try {
      remoteRenderer = await WebRTCService.initializeRenderer();

      WebRTCService.setOnRemoteStreamReady((renderer) {
        final alreadyReady =
            hasReceivedOffer && identical(remoteRenderer, renderer);
        remoteRenderer = renderer;
        hasReceivedOffer = true;
        isConnected = true;
        connectionStatus = 'stream_connected'.tr;
        // Avoid rebuild storms that recreate EglRenderer and drop frames.
        if (!alreadyReady) {
          notifyListeners();
        }
      });

      WebRTCService.setOnConnectionStateChanged((state) {
        if (state == 'stream_connected') {
          connectionStatus = 'stream_connected'.tr;
          isConnected = true;
        } else if (state == 'receiving_stream') {
          connectionStatus = 'receiving_stream'.tr;
        } else if (state == 'stream_ended') {
          isStreaming = false;
          hasReceivedOffer = false;
          isConnected = false;
          connectionStatus = 'stream_not_available'.tr;
        } else if (state == 'failed' ||
            state == 'disconnected' ||
            state == 'closed') {
          isConnected = false;
          connectionStatus = state;
        } else {
          connectionStatus = state;
        }
        notifyListeners();
      });

      WebRTCService.setOnError((errorMsg) {
        error = errorMsg;
        connectionStatus = 'connection_error'.tr;
        notifyListeners();
      });

      await WebRTCService.initializeSignaling(sessionId);

      connectionStatus = 'waiting_for_stream'.tr;
      _initializedForSession = true;
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
    error = null;
    _initializedForSession = false;
    await loadStreamingStatus(sessionId);
  }

  bool shouldAutoLoad(String sessionId) {
    return !_initializedForSession || _activeSessionId != sessionId;
  }

  @override
  void dispose() {
    WebRTCService.disconnect();
    StreamingService.disconnect();
    super.dispose();
  }
}
