import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../utils/chat_logger.dart';

class ChatProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<ChatMessageModel> _messages = [];
  String? currentLabId;
  String? currentChannel;
  final Set<String> _messageIds = {};
  StreamSubscription<ChatMessageModel>? _messageSubscription;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  Future<void> init({required String channel, String? labId}) async {
    currentChannel = channel;
    currentLabId = labId;
    _messageIds.clear();
    ChatLogger.logProviderInit(channel, labId);

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final fetchedMessages = await ChatService.getMessages(
        channel: currentChannel,
        labId: labId,
        limit: 50,
      );

      fetchedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messages = fetchedMessages;

      for (final msg in _messages) {
        _messageIds.add(msg.id);
      }

      _messageSubscription?.cancel();
      _messageSubscription = ChatService.messageStream.listen((message) {
        if (_messageIds.contains(message.id)) return;
        _messageIds.add(message.id);
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      });

      ChatService.setOnError((errorMessage) {
        error = errorMessage;
        notifyListeners();
      });

      await ChatService.initializeSocket(
        currentChannel!,
        labId: labId,
      );

      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('401') && errorString.contains('Unauthorized')) {
        error = 'Authentication failed. Please try again.';
      } else {
        error = errorString;
      }
      ChatLogger.logError('Provider init', e);
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initLab(String labId) async {
    await init(channel: 'lab:$labId', labId: labId);
  }

  Future<bool> sendMessage({
    String? content,
    List<String>? fileIds,
  }) async {
    if (currentChannel == null) {
      error = 'No channel selected';
      notifyListeners();
      return false;
    }

    final connected = await ChatService.ensureConnected(
      channel: currentChannel!,
      labId: currentLabId,
    );
    if (!connected) {
      error = 'Chat connection failed. Please try again.';
      notifyListeners();
      return false;
    }

    final text = (content ?? '').trim();
    final resolvedContent = text.isNotEmpty
        ? text
        : (fileIds != null && fileIds.isNotEmpty
              ? 'Attachment message (${fileIds.length} file(s))'
              : '');
    if (resolvedContent.isEmpty) {
      error = 'Message cannot be empty';
      notifyListeners();
      return false;
    }

    try {
      final created = await ChatService.sendMessageRest(
        channel: currentChannel!,
        content: resolvedContent,
        labId: currentLabId,
      );
      if (!_messageIds.contains(created.id)) {
        _messageIds.add(created.id);
        _messages.add(created);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void leaveCurrentChannel() {
    if (currentChannel != null) {
      ChatService.leaveChannel(currentChannel!);
    }
    _messageSubscription?.cancel();
    _messageSubscription = null;
    ChatService.disconnect();
    _messages.clear();
    _messageIds.clear();
    currentLabId = null;
    currentChannel = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    leaveCurrentChannel();
    super.dispose();
  }

  Future<void> initializeChat(String labId) async {
    await initLab(labId);
  }

  void leave() {
    leaveCurrentChannel();
  }
}
