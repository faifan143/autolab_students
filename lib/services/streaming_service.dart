import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/session_model.dart';
import 'sessions_service.dart';
import 'storage_service.dart';

/// Streaming service - handles WebSocket connection for WebRTC streaming
class StreamingService {
  static IO.Socket? _socket;
  static Function(Map<String, dynamic>)? _onStreamOfferReceived;
  static String? _currentSessionId;

  /// Get session streaming status
  static Future<SessionModel> getSessionStreamingStatus(String sessionId) async {
    // For now, just return the session which contains isStreaming flag
    return await SessionsService.getSession(sessionId);
  }

  /// Initialize socket connection for streaming
  static Future<void> initializeStreamingSocket(String sessionId) async {
    final baseUrl = await StorageService.getBaseUrl();
    final token = await StorageService.getAccessToken();

    // Disconnect existing socket if any
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _currentSessionId = sessionId;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      // Join the streaming room for this session
      _socket!.emit('join-streaming', {'sessionId': sessionId});
    });

    // Listen for streamOffer event from teacher
    _socket!.on('streamOffer', (data) {
      if (_onStreamOfferReceived != null) {
        _onStreamOfferReceived!(data as Map<String, dynamic>);
      }
    });

    // Listen for streamEnd event
    _socket!.on('streamEnd', (_) {
      if (_onStreamOfferReceived != null) {
        _onStreamOfferReceived!({'type': 'streamEnd'});
      }
    });

    _socket!.onDisconnect((_) {
      // Handle disconnect
    });

    _socket!.onError((error) {
      // Handle error
    });
  }

  /// Set callback for incoming stream offer
  static void setOnStreamOfferReceived(Function(Map<String, dynamic>) callback) {
    _onStreamOfferReceived = callback;
  }

  /// Send WebRTC answer to teacher
  static void sendStreamAnswer(Map<String, dynamic> answer) {
    if (_socket != null && _socket!.connected && _currentSessionId != null) {
      _socket!.emit('streamAnswer', {
        'sessionId': _currentSessionId,
        'answer': answer,
      });
    }
  }

  /// Disconnect streaming socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _currentSessionId = null;
    _onStreamOfferReceived = null;
  }

  /// Check if socket is connected
  static bool get isConnected => _socket != null && _socket!.connected;
}

