import 'dart:async';

import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/jwt_utils.dart';
import 'storage_service.dart';

/// Mediasoup SFU consumer for live session streaming (`/ws/streaming`).
class WebRTCService {
  static IO.Socket? _socket;
  static String? _currentSessionId;
  static Device? _device;
  static Transport? _recvTransport;
  static String? _transportId;
  static RTCVideoRenderer? _remoteRenderer;
  static MediaStream? _remoteStream;
  static final Set<String> _consumedProducerIds = {};
  static final Map<String, Consumer> _consumers = {};
  static Completer<void>? _transportConnectCompleter;
  static bool _joining = false;
  static Timer? _videoRecoveryTimer;

  static Function(RTCVideoRenderer)? _onRemoteStreamReady;
  static Function(String)? _onConnectionStateChanged;
  static Function(String)? _onError;

  /// Kept for API compatibility with the old P2P path (no-op for SFU).
  static Future<void> initializePeerConnection() async {}

  static Future<RTCVideoRenderer> initializeRenderer() async {
    if (_remoteRenderer != null) {
      return _remoteRenderer!;
    }
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer!.initialize();
    return _remoteRenderer!;
  }

  static Future<void> initializeSignaling(String sessionId) async {
    await disconnect(keepCallbacks: true, keepRenderer: true);

    final baseUrl = await StorageService.getBaseUrl();
    final token = await StorageService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token available');
    }

    final cleanToken = token.replaceFirst('Bearer ', '');
    final payload = JwtUtils.decodePayload(cleanToken);
    final userId =
        (payload?['sub'] ?? payload?['userId'] ?? payload?['id'])?.toString();
    final role = (payload?['role'] ?? 'student').toString();

    if (userId == null || userId.isEmpty) {
      throw Exception('Could not read user id from token');
    }

    _currentSessionId = sessionId;
    _joining = false;

    final wsUrl = '$baseUrl/ws/streaming';
    _socket = IO.io(
      wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({
            'userId': userId,
            'role': role,
            'token': cleanToken,
          })
          .setExtraHeaders({'Authorization': 'Bearer $cleanToken'})
          .setTimeout(15000)
          .build(),
    );

    _setupSocketListeners();
    _socket!.connect();
  }

  static void _setupSocketListeners() {
    final socket = _socket!;

    socket.onConnect((_) {
      _onConnectionStateChanged?.call('connecting');
      _requestRouterCapabilities();
    });

    socket.onDisconnect((_) {
      _onConnectionStateChanged?.call('disconnected');
    });

    socket.on('connect_error', (error) {
      _onError?.call(error.toString());
    });

    socket.on('stream-error', (data) {
      final message = data is Map
          ? (data['message']?.toString() ?? 'Stream error')
          : data.toString();
      _onError?.call(message);
    });

    socket.on('router-rtp-capabilities', (data) async {
      try {
        final map = _asStringKeyedMap(data);
        if (map['sessionId']?.toString() != _currentSessionId) return;

        final capsRaw = map['rtpCapabilities'];
        if (capsRaw is! Map) {
          throw Exception('Invalid router RTP capabilities');
        }

        _device = Device();
        await _device!.load(
          routerRtpCapabilities: RtpCapabilities.fromMap(
            _asStringKeyedMap(capsRaw),
          ),
        );

        socket.emit('create-transport', {
          'sessionId': _currentSessionId,
          'type': 'consumer',
        });
      } catch (e) {
        _onError?.call(e.toString());
      }
    });

    socket.on('transport-created', (data) async {
      try {
        final map = _asStringKeyedMap(data);
        if (map['sessionId']?.toString() != _currentSessionId) return;

        final params = map['params'];
        if (params is! Map) {
          throw Exception('Invalid transport params');
        }

        await _createRecvTransport(_asStringKeyedMap(params));
        socket.emit('get-producers', {'sessionId': _currentSessionId});
      } catch (e) {
        _onError?.call(e.toString());
      }
    });

    socket.on('transport-connected', (data) {
      final map = _asStringKeyedMap(data);
      if (map['transportId']?.toString() == _transportId) {
        _transportConnectCompleter?.complete();
        _transportConnectCompleter = null;
      }
    });

    socket.on('producers', (data) async {
      final map = _asStringKeyedMap(data);
      if (map['sessionId']?.toString() != _currentSessionId) return;

      final producers = map['producers'];
      if (producers is! List) return;

      // Consume video before audio so the renderer gets a video track first.
      final ordered = [...producers]..sort((a, b) {
          final ak = a is Map ? a['kind']?.toString() : null;
          final bk = b is Map ? b['kind']?.toString() : null;
          if (ak == 'video' && bk != 'video') return -1;
          if (bk == 'video' && ak != 'video') return 1;
          return 0;
        });

      for (final producer in ordered) {
        if (producer is! Map) continue;
        final id = producer['id']?.toString();
        if (id != null) {
          await _consumeProducer(id);
        }
      }
    });

    socket.on('stream-started', (data) async {
      final map = _asStringKeyedMap(data);
      if (map['sessionId']?.toString() != _currentSessionId) return;

      final producerId = map['producerId']?.toString();
      if (producerId != null) {
        await _consumeProducer(producerId);
      } else {
        socket.emit('get-producers', {'sessionId': _currentSessionId});
      }
    });

    socket.on('stream-started-notification', (_) {
      socket.emit('get-producers', {'sessionId': _currentSessionId});
    });

    socket.on('consumed', (data) async {
      try {
        final map = _asStringKeyedMap(data);
        if (map['sessionId']?.toString() != _currentSessionId) return;
        await _attachConsumer(map);
      } catch (e) {
        _onError?.call(e.toString());
      }
    });

    socket.on('stream-stopped', (_) {
      _onConnectionStateChanged?.call('stream_ended');
      _clearMedia(keepRenderer: true);
    });

    socket.onError((error) {
      _onError?.call(error.toString());
    });
  }

  static void _requestRouterCapabilities() {
    if (_socket == null || _currentSessionId == null) return;
    _socket!.emit('get-router-rtp-capabilities', {
      'sessionId': _currentSessionId,
    });
  }

  static Future<void> _createRecvTransport(Map<String, dynamic> params) async {
    if (_device == null) {
      throw Exception('Device not loaded');
    }

    _transportId = params['id']?.toString();

    final iceParameters = Map<String, dynamic>.from(
      params['iceParameters'] as Map,
    );
    iceParameters['iceLite'] ??= true;

    final normalized = <String, dynamic>{
      'id': params['id'],
      'iceParameters': iceParameters,
      'iceCandidates': params['iceCandidates'],
      'dtlsParameters': params['dtlsParameters'],
      if (params['sctpParameters'] != null)
        'sctpParameters': params['sctpParameters'],
    };

    _recvTransport?.close();
    _recvTransport = _device!.createRecvTransportFromMap(
      normalized,
      consumerCallback: (Consumer consumer, [dynamic accept]) {
        accept?.call({});
        _onConsumerReady(consumer);
      },
    );

    _recvTransport!.on('connect', (Map data) async {
      final DtlsParameters dtlsParameters = data['dtlsParameters'];
      final Function callback = data['callback'];
      final Function errback = data['errback'];

      try {
        _transportConnectCompleter = Completer<void>();
        _socket!.emit('connect-transport', {
          'transportId': _transportId,
          'dtlsParameters': dtlsParameters.toMap(),
        });

        await _transportConnectCompleter!.future.timeout(
          const Duration(seconds: 15),
        );
        callback();
        // DTLS up is not the same as video frames arriving.
        _onConnectionStateChanged?.call('receiving_stream');
      } catch (e) {
        errback(e);
        _onError?.call(e.toString());
      }
    });

    _recvTransport!.on('connectionstatechange', (Map data) {
      final state = data['connectionState']?.toString() ?? 'unknown';
      // Keep UI/status accurate: only "connected" once video is attached.
      if (state == 'failed' || state == 'disconnected' || state == 'closed') {
        _onConnectionStateChanged?.call(state);
      } else if (_remoteStream?.getVideoTracks().isNotEmpty != true) {
        _onConnectionStateChanged?.call('receiving_stream');
      }
    });
  }

  static Future<void> _consumeProducer(String producerId) async {
    if (_joining) return;
    if (_consumedProducerIds.contains(producerId)) return;
    if (_socket == null ||
        _device == null ||
        _recvTransport == null ||
        _transportId == null ||
        _currentSessionId == null) {
      return;
    }

    _consumedProducerIds.add(producerId);
    _socket!.emit('consume', {
      'sessionId': _currentSessionId,
      'transportId': _transportId,
      'producerId': producerId,
      'rtpCapabilities': _rtpCapabilitiesToMap(_device!.rtpCapabilities),
    });
  }

  static Future<void> _attachConsumer(Map<String, dynamic> data) async {
    if (_recvTransport == null) return;

    final consumerId = data['consumerId']?.toString();
    final producerId = data['producerId']?.toString();
    final kind = data['kind']?.toString();
    final rtpParametersRaw = data['rtpParameters'];

    if (consumerId == null ||
        producerId == null ||
        kind == null ||
        rtpParametersRaw is! Map) {
      throw Exception('Invalid consumed payload');
    }

    final mediaType = kind == 'audio'
        ? RTCRtpMediaType.RTCRtpMediaTypeAudio
        : RTCRtpMediaType.RTCRtpMediaTypeVideo;

    _recvTransport!.consume(
      id: consumerId,
      producerId: producerId,
      peerId: 'teacher',
      kind: mediaType,
      rtpParameters: RtpParameters.fromMap(_asStringKeyedMap(rtpParametersRaw)),
    );
  }

  static void _onConsumerReady(Consumer consumer) {
    _consumers[consumer.id] = consumer;

    final renderer = _remoteRenderer;
    if (renderer == null) return;

    try {
      consumer.track.enabled = true;
    } catch (_) {}

    final kind = consumer.kind;

    // Never MediaStream.addTrack() on mediasoup streams — on Android the
    // native stream id is not registered for that API and it throws
    // mediaStreamAddTrack() stream [...] is null, which breaks playback.
    // Keep video and audio on their own consumer.stream objects.
    if (kind == 'video') {
      _remoteStream = consumer.stream;
      // Force a clean first attach on Android so the visible renderer is the
      // one receiving frames (avoids hidden renderer receiving frames).
      renderer.srcObject = null;
      renderer.srcObject = _remoteStream;
      _resumeConsumer(consumer.id);
      _startVideoRecoveryLoop(consumer.id);
      _onRemoteStreamReady?.call(renderer);
      _onConnectionStateChanged?.call('stream_connected');
      return;
    }

    if (kind == 'audio') {
      // Audio plays from the PeerConnection track automatically; do not
      // splice it into the video MediaStream used by RTCVideoView.
      _resumeConsumer(consumer.id);
      return;
    }
  }

  static void _resumeConsumer(String consumerId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('resume-consumer', {'consumerId': consumerId});
  }

  static void _startVideoRecoveryLoop(String consumerId) {
    _videoRecoveryTimer?.cancel();
    var attempts = 0;
    _videoRecoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      attempts += 1;
      // Re-ask SFU to resume/request keyframe in case first keyframe was missed.
      _resumeConsumer(consumerId);
      if (attempts >= 6) {
        timer.cancel();
      }
    });
  }

  static Map<String, dynamic> _rtpCapabilitiesToMap(RtpCapabilities caps) {
    return {
      'codecs': caps.codecs.map((c) => c.toMap()).toList(),
      'headerExtensions': caps.headerExtensions.map((h) {
        return <String, dynamic>{
          if (h.kind != null)
            'kind': RTCRtpMediaTypeExtension.value(h.kind!),
          'uri': h.uri,
          'preferredId': h.preferredId,
          'preferredEncrypt': h.preferredEncrypt,
          if (h.direction != null) 'direction': h.direction!.value,
        };
      }).toList(),
    };
  }

  static Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    throw Exception('Expected map, got ${value.runtimeType}');
  }

  static void setOnRemoteStreamReady(Function(RTCVideoRenderer) callback) {
    _onRemoteStreamReady = callback;
  }

  static void setOnConnectionStateChanged(Function(String) callback) {
    _onConnectionStateChanged = callback;
  }

  static void setOnError(Function(String) callback) {
    _onError = callback;
  }

  static RTCVideoRenderer? get remoteRenderer => _remoteRenderer;

  static bool get isConnected =>
      _remoteStream != null && _remoteStream!.getVideoTracks().isNotEmpty;

  static void _clearMedia({bool keepRenderer = false}) {
    for (final consumer in _consumers.values) {
      try {
        consumer.close();
      } catch (_) {}
    }
    _consumers.clear();
    _consumedProducerIds.clear();
    _videoRecoveryTimer?.cancel();
    _videoRecoveryTimer = null;

    try {
      _recvTransport?.close();
    } catch (_) {}
    _recvTransport = null;
    _transportId = null;
    _device = null;

    _remoteStream = null;
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null;
    }
  }

  static Future<void> disconnect({
    bool keepCallbacks = false,
    bool keepRenderer = false,
  }) async {
    _joining = false;
    if (_transportConnectCompleter != null &&
        !_transportConnectCompleter!.isCompleted) {
      _transportConnectCompleter!.completeError('disconnected');
    }
    _transportConnectCompleter = null;

    _clearMedia(keepRenderer: keepRenderer);

    if (!keepRenderer) {
      if (_remoteRenderer != null) {
        await _remoteRenderer!.dispose();
        _remoteRenderer = null;
      }
      _remoteStream = null;
    }

    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _currentSessionId = null;

    if (!keepCallbacks) {
      _onRemoteStreamReady = null;
      _onConnectionStateChanged = null;
      _onError = null;
    }
  }
}
