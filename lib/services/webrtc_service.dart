import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'storage_service.dart';

/// WebRTC service for real-time video streaming
class WebRTCService {
  static RTCPeerConnection? _peerConnection;
  static RTCVideoRenderer? _remoteRenderer;
  static IO.Socket? _socket;
  static String? _currentSessionId;
  static Function(RTCVideoRenderer)? _onRemoteStreamReady;
  static Function(String)? _onConnectionStateChanged;
  static Function(String)? _onError;

  /// Initialize WebRTC peer connection
  static Future<void> initializePeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_socket != null && _socket!.connected && _currentSessionId != null) {
        _socket!.emit('iceCandidate', {
          'sessionId': _currentSessionId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
          },
        });
      }
    };

    // Handle remote stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty && _remoteRenderer != null) {
        _remoteRenderer!.srcObject = event.streams[0];
        if (_onRemoteStreamReady != null) {
          _onRemoteStreamReady!(_remoteRenderer!);
        }
      }
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      final stateString = state.toString().split('.').last;
      if (_onConnectionStateChanged != null) {
        _onConnectionStateChanged!(stateString);
      }
    };
  }

  /// Initialize video renderer
  static Future<RTCVideoRenderer> initializeRenderer() async {
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
    return _remoteRenderer!;
  }

  /// Initialize WebSocket connection for signaling
  static Future<void> initializeSignaling(String sessionId) async {
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
      _socket!.emit('join-streaming', {'sessionId': sessionId});
    });

    // Listen for streamOffer
    _socket!.on('streamOffer', (data) async {
      try {
        final offerData = data as Map<String, dynamic>;
        await _handleOffer(offerData);
      } catch (e) {
        if (_onError != null) {
          _onError!(e.toString());
        }
      }
    });

    // Listen for ICE candidates from teacher
    _socket!.on('iceCandidate', (data) async {
      try {
        final candidateData = data as Map<String, dynamic>;
        final candidate = RTCIceCandidate(
          candidateData['candidate']['candidate'],
          candidateData['candidate']['sdpMid'],
          candidateData['candidate']['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        if (_onError != null) {
          _onError!(e.toString());
        }
      }
    });

    // Listen for streamEnd
    _socket!.on('streamEnd', (_) {
      disconnect();
    });

    _socket!.onError((error) {
      if (_onError != null) {
        _onError!(error.toString());
      }
    });
  }

  /// Handle incoming WebRTC offer from teacher
  static Future<void> _handleOffer(Map<String, dynamic> offerData) async {
    if (_peerConnection == null) {
      await initializePeerConnection();
    }

    final offer = RTCSessionDescription(
      offerData['sdp'] as String,
      offerData['type'] as String,
    );

    await _peerConnection!.setRemoteDescription(offer);

    // Create answer
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Send answer back to teacher
    if (_socket != null && _socket!.connected && _currentSessionId != null) {
      _socket!.emit('streamAnswer', {
        'sessionId': _currentSessionId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
    }
  }

  /// Set callbacks
  static void setOnRemoteStreamReady(Function(RTCVideoRenderer) callback) {
    _onRemoteStreamReady = callback;
  }

  static void setOnConnectionStateChanged(Function(String) callback) {
    _onConnectionStateChanged = callback;
  }

  static void setOnError(Function(String) callback) {
    _onError = callback;
  }

  /// Get remote video renderer
  static RTCVideoRenderer? get remoteRenderer => _remoteRenderer;

  /// Check if peer connection is established
  static bool get isConnected =>
      _peerConnection != null &&
      _peerConnection!.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  /// Disconnect and cleanup
  static Future<void> disconnect() async {
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }

    if (_remoteRenderer != null) {
      await _remoteRenderer!.dispose();
      _remoteRenderer = null;
    }

    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _currentSessionId = null;
    _onRemoteStreamReady = null;
    _onConnectionStateChanged = null;
    _onError = null;
  }
}

