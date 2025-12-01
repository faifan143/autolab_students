import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_message_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ChatService {
  static IO.Socket? _socket;
  static Function(ChatMessageModel)? _onMessageReceived;

  /// Initialize socket connection for lab chat
  static Future<void> initializeSocket(String labId) async {
    final baseUrl = await StorageService.getBaseUrl();
    final token = await StorageService.getAccessToken();

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('join-lab', labId);
    });

    _socket!.on('message', (data) {
      if (_onMessageReceived != null) {
        final message = ChatMessageModel.fromJson(data);
        _onMessageReceived!(message);
      }
    });

    _socket!.onDisconnect((_) {
      // Handle disconnect
    });
  }

  /// Set callback for incoming messages
  static void setOnMessageReceived(Function(ChatMessageModel) callback) {
    _onMessageReceived = callback;
  }

  /// Send a message
  static void sendMessage(String labId, String content) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send-message', {
        'labId': labId,
        'content': content,
      });
    }
  }

  /// Get chat history via REST
  static Future<List<ChatMessageModel>> getChatHistory(String labId) async {
    final dio = await ApiService.dio;
    final response = await dio.get(
      ApiEndpoints.chatMessages,
      queryParameters: {'labId': labId},
    );
    
    final List<dynamic> data = response.data;
    return data.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  /// Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _onMessageReceived = null;
  }
}

