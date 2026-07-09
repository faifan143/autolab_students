import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_message_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/chat_logger.dart';

class ChatService {
  static IO.Socket? _socket;
  static Function(ChatMessageModel)? _onMessageReceived;
  static Function(String)? _onError;
  static String? _pendingChannel;
  static String? _pendingLabId;
  static bool _isConnected = false;
  static final StreamController<ChatMessageModel> _messageController = StreamController<ChatMessageModel>.broadcast();
  
  /// Message stream for listening to incoming messages
  static Stream<ChatMessageModel> get messageStream => _messageController.stream;

  /// Get WebSocket base URL
  /// Socket.IO needs http:// or https:// (not ws://), it will handle the WebSocket upgrade internally
  static Future<String> _getWsBaseUrl() async {
    final baseUrl = await StorageService.getBaseUrl();
    // Socket.IO works with http:// or https:// URLs and handles WebSocket upgrade
    return baseUrl;
  }

  /// Get WebSocket path
  static String _getWsPath() {
    return '/ws/teachers';
  }

  /// Connect WebSocket (alias for initializeSocket for spec compatibility)
  static Future<void> connect() async {
    // This will be called after setting pending channel/labId
    await _connectInternal();
  }

  /// Initialize socket connection for lab chat
  static Future<void> initializeSocket(String channel, {String? labId}) async {
    _pendingChannel = channel;
    _pendingLabId = labId;
    await _connectInternal();
  }

  static Future<void> _connectInternal() async {
    if (_isConnected && _socket != null && _socket!.connected) {
      ChatLogger.debug('Already connected, skipping connection attempt');
      return;
    }

    final baseUrl = await _getWsBaseUrl();
    final token = await StorageService.getAccessToken();
    
    if (token == null || token.isEmpty) {
      throw Exception('No access token available');
    }

    // Clean token (remove Bearer prefix if present)
    final cleanToken = token.replaceFirst('Bearer ', '');
    final tokenPreview = cleanToken.length > 10 ? '${cleanToken.substring(0, 10)}...' : cleanToken;

    // Disconnect existing socket if any
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    // Match teachers app flow: connect directly to namespace URL.
    final wsUrl = '$baseUrl${_getWsPath()}';
    ChatLogger.logConnectionAttempt(wsUrl, tokenPreview);

    _socket = IO.io(
      wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $cleanToken'})
          .setAuth({'token': cleanToken})
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setTimeout(10000)
          .build(),
    );

    _setupEventListeners();
  }

  static void _setupEventListeners() {
    _socket!.onConnect((_) {
      _isConnected = true;
      final socketId = _socket!.id;
      ChatLogger.logConnectionSuccess(socketId);
      
      // Join pending channel if any
      if (_pendingChannel != null) {
        joinChannel(_pendingChannel!, labId: _pendingLabId);
        _pendingChannel = null;
        _pendingLabId = null;
      }
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      ChatLogger.logDisconnection(reason);
      if (_onError != null && reason == 'io server disconnect') {
        _onError!('Server disconnected: $reason');
      }
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      ChatLogger.logConnectionError(error);
      if (_onError != null) {
        _onError!('Connection error: $error');
      }
    });

    _socket!.on('exception', (data) {
      ChatLogger.logError('WebSocket exception', data);
      if (_onError != null) {
        _onError!('Server exception: $data');
      }
    });

    _socket!.on('chat:message-created', (data) {
      try {
        final message = ChatMessageModel.fromJson(data as Map<String, dynamic>);
        ChatLogger.logMessageReceived(
          message.id,
          message.channel,
          message.senderId,
          message.sender?.name,
          message.content,
          message.labId,
          message.fileIds,
        );
        
        // Add to stream
        _messageController.add(message);
        
        // Also call callback for backward compatibility
        if (_onMessageReceived != null) {
          _onMessageReceived!(message);
        }
      } catch (e) {
        ChatLogger.logMessageParseError(e, data);
        if (_onError != null) {
          _onError!('Error parsing message: $e');
        }
      }
    });

    _socket!.on('channel-joined', (data) {
      final channel = data is Map ? (data['channel'] ?? _pendingChannel) : _pendingChannel;
      final labId = data is Map ? data['labId'] : _pendingLabId;
      ChatLogger.logChannelJoined(channel?.toString() ?? '', labId?.toString());
    });

    _socket!.on('channel-left', (data) {
      final channel = data is Map ? data['channel'] : data?.toString();
      ChatLogger.logChannelLeft(channel?.toString() ?? '');
    });

    _socket!.on('message-sent', (data) {
      final messageId = data is Map ? data['messageId'] : null;
      final channel = data is Map ? data['channel'] : _pendingChannel;
      ChatLogger.logMessageSent(messageId?.toString() ?? '', channel?.toString() ?? '');
    });

    _socket!.on('chat-error', (data) {
      final errorData = data is Map ? data : {'message': data?.toString() ?? 'Chat error occurred'};
      ChatLogger.logError('Chat error', errorData);
      if (_onError != null) {
        _onError!(errorData['message'] ?? 'Chat error occurred');
      }
    });
  }

  /// Join a chat channel
  static void joinChannel(String channel, {String? labId}) {
    if (_socket == null || !_socket!.connected) {
      // Queue channel join for when connection is ready
      _pendingChannel = channel;
      _pendingLabId = labId;
      ChatLogger.logChannelJoinAttempt(channel, labId);
      return;
    }

    ChatLogger.logChannelJoinAttempt(channel, labId);
    final payload = <String, dynamic>{
      'channel': channel,
    };
    if (labId != null) {
      payload['labId'] = labId;
    }

    _socket!.emit('join-channel', payload);
  }

  /// Leave a chat channel
  static void leaveChannel(String channel) {
    if (_socket == null || !_socket!.connected) {
      return;
    }

    _socket!.emit('leave-channel', {'channel': channel});
  }

  /// Set callback for incoming messages
  static void setOnMessageReceived(Function(ChatMessageModel) callback) {
    _onMessageReceived = callback;
  }

  /// Set callback for errors
  static void setOnError(Function(String) callback) {
    _onError = callback;
  }

  /// Send a message
  static bool sendMessage({
    required String channel,
    String? content,
    String? labId,
    List<String>? fileIds,
  }) {
    if (_socket == null || !_socket!.connected) {
      ChatLogger.logMessageSendError(channel, 'Socket not connected');
      if (_onError != null) {
        _onError!('Socket not connected');
      }
      return false;
    }

    // Validation: message must have content OR at least one fileId
    if ((content == null || content.trim().isEmpty) && 
        (fileIds == null || fileIds.isEmpty)) {
      ChatLogger.logMessageSendError(channel, 'Message must have content or at least one file');
      if (_onError != null) {
        _onError!('Message must have content or at least one file');
      }
      return false;
    }

    // Max 10 files
    if (fileIds != null && fileIds.length > 10) {
      ChatLogger.logMessageSendError(channel, 'Maximum 10 files allowed per message');
      if (_onError != null) {
        _onError!('Maximum 10 files allowed per message');
      }
      return false;
    }

    ChatLogger.logMessageSend(channel, content, labId, fileIds);

    final payload = <String, dynamic>{
      'channel': channel,
    };
    
    if (content != null && content.trim().isNotEmpty) {
      payload['content'] = content.trim();
    }
    
    if (labId != null) {
      payload['labId'] = labId;
    }
    
    if (fileIds != null && fileIds.isNotEmpty) {
      payload['fileIds'] = fileIds;
    }

    _socket!.emit('send-message', payload);
    return true;
  }

  /// Ensure socket is connected.
  static Future<bool> ensureConnected({
    required String channel,
    String? labId,
    int timeoutMs = 6000,
  }) async {
    if (isConnected) return true;

    try {
      await initializeSocket(channel, labId: labId);
    } catch (_) {
      return false;
    }

    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < timeoutMs) {
      if (isConnected) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return isConnected;
  }

  /// Send message via REST API (backend-supported flow).
  static Future<ChatMessageModel> sendMessageRest({
    required String channel,
    String? content,
    String? labId,
    List<String>? fileIds,
  }) async {
    final trimmed = content?.trim();
    if ((trimmed == null || trimmed.isEmpty) &&
        (fileIds == null || fileIds.isEmpty)) {
      throw Exception('Message must include content or attachments');
    }
    final dio = await ApiService.dio;
    final response = await dio.post(
      ApiEndpoints.chatMessages,
      data: {
        'channel': channel,
        if (trimmed != null && trimmed.isNotEmpty) 'content': trimmed,
        if (labId != null) 'labId': labId,
        if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
      },
    );
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get chat messages via REST API
  static Future<List<ChatMessageModel>> getMessages({
    String? channel,
    String? labId,
    int limit = 50,
    int? offset,
  }) async {
    ChatLogger.logMessageFetch(channel, labId, limit, offset);
    
    try {
      final dio = await ApiService.dio;
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      // Only include offset if it's provided and positive (server requires positive number)
      if (offset != null && offset > 0) {
        queryParams['offset'] = offset;
      }
      
      if (channel != null) {
        queryParams['channel'] = channel;
      }
      
      if (labId != null) {
        queryParams['labId'] = labId;
      }

      final response = await dio.get(
        ApiEndpoints.chatMessages,
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data;
      final messages = data.map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>)).toList();
      ChatLogger.logMessageFetch(channel, labId, limit, offset, messages.length);
      return messages;
    } catch (e) {
      ChatLogger.logMessageFetchError(channel ?? '', e);
      rethrow;
    }
  }

  /// Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
    _onMessageReceived = null;
    _onError = null;
    _pendingChannel = null;
    _pendingLabId = null;
  }

  /// Check if socket is connected
  static bool get isConnected => _isConnected && _socket != null && _socket!.connected;
}

