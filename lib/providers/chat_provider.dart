import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<ChatMessageModel> messages = [];
  String? currentLabId;

  Future<void> initializeChat(String labId) async {
    currentLabId = labId;

    // Load history
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      messages = await ChatService.getChatHistory(labId);

      // Initialize socket
      ChatService.setOnMessageReceived((message) {
        messages.add(message);
        notifyListeners();
      });

      await ChatService.initializeSocket(labId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  void sendMessage(String content) {
    if (currentLabId != null) {
      ChatService.sendMessage(currentLabId!, content);
    }
  }

  @override
  void dispose() {
    ChatService.disconnect();
    super.dispose();
  }
}
