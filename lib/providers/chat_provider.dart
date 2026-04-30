import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../utils/chat_logger.dart';

class ChatProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<ChatMessageModel> _messages = [];
  String? currentLabId;
  String? currentChannel;
  final Set<String> _messageIds = {}; // For deduplication
  final Map<String, UserModel> _senderCache = {}; // Cache for sender information
  StreamSubscription<ChatMessageModel>? _messageSubscription;

  /// Get unmodifiable message list
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  /// Initialize chat for a lab
  /// This follows the implementation flow from the specification
  Future<void> init({required String channel, String? labId}) async {
    currentChannel = channel;
    currentLabId = labId;
    _messageIds.clear();
    ChatLogger.logProviderInit(channel, labId);

    // Step 1: Fetch message history via REST
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Fetch messages with channel and labId
      // ApiService will automatically handle 401 errors and retry with refreshed token
      final fetchedMessages = await ChatService.getMessages(
        channel: currentChannel,
        labId: labId,
        limit: 50,
      );

      // Step 2: Sort messages by createdAt (oldest → newest)
      fetchedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Step 2.5: Populate sender information for messages
      _messages = await _populateSenders(fetchedMessages);
      
      // Track message IDs for deduplication
      for (var msg in _messages) {
        _messageIds.add(msg.id);
      }

      // Step 3: Set up message stream subscription before connecting
      _messageSubscription?.cancel();
      _messageSubscription = ChatService.messageStream.listen((message) async {
        // Deduplicate messages
        if (!_messageIds.contains(message.id)) {
          _messageIds.add(message.id);
          // Populate sender if not already populated
          ChatMessageModel messageWithSender = message;
          if (message.sender == null && message.senderId.isNotEmpty) {
            messageWithSender = await _getMessageWithSender(message);
          }
          _messages.add(messageWithSender);
          // Keep messages sorted by createdAt
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();
        }
      });

      // Set up error callback (backward compatibility)
      ChatService.setOnError((errorMessage) {
        error = errorMessage;
        notifyListeners();
      });

      // Step 4: Connect WebSocket
      await ChatService.initializeSocket(
        currentChannel!,
        labId: labId,
      );

      // Step 5: Join channel (handled in initializeSocket if connected, or queued)
      // The join is automatically handled in initializeSocket's onConnect callback

      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      // Check if it's a DioException with 401 - ApiService should handle retry
      // Only show error if it's not a 401 (which should be retried automatically)
      final errorString = e.toString();
      if (errorString.contains('401') && errorString.contains('Unauthorized')) {
        // 401 errors are handled by ApiService with automatic retry
        // If we still get an error, it means retry failed or token is invalid
        error = 'Authentication failed. Please try again.';
      } else {
        error = errorString;
      }
      ChatLogger.logError('Provider init', e);
      isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize chat for a lab (backward compatibility)
  Future<void> initLab(String labId) async {
    await init(channel: 'lab:$labId', labId: labId);
  }

  /// Send a message
  /// Files should be uploaded first via FilesProvider.uploadFile()
  void sendMessage({
    String? content,
    List<String>? fileIds,
  }) {
    if (currentChannel == null) {
      error = 'No channel selected';
      notifyListeners();
      return;
    }

    ChatService.sendMessage(
      channel: currentChannel!,
      content: content,
      labId: currentLabId,
      fileIds: fileIds,
    );
  }

  /// Leave current channel and disconnect
  void leaveCurrentChannel() {
    if (currentChannel != null) {
      ChatService.leaveChannel(currentChannel!);
    }
    _messageSubscription?.cancel();
    _messageSubscription = null;
    ChatService.disconnect();
    _messages.clear();
    _messageIds.clear();
    _senderCache.clear();
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

  // Backward compatibility methods
  Future<void> initializeChat(String labId) async {
    await initLab(labId);
  }

  void leave() {
    leaveCurrentChannel();
  }

  /// Populate sender information for a list of messages
  Future<List<ChatMessageModel>> _populateSenders(List<ChatMessageModel> messages) async {
    // Collect unique senderIds that don't have sender information
    final senderIdsToFetch = <String>{};
    for (var message in messages) {
      if (message.sender == null && message.senderId.isNotEmpty) {
        senderIdsToFetch.add(message.senderId);
      }
    }

    // Fetch sender information for all unique senderIds
    for (var senderId in senderIdsToFetch) {
      if (_senderCache.containsKey(senderId)) {
        // Use cached sender
        continue;
      }
      
      try {
        final sender = await UserService.getUserById(senderId);
        _senderCache[senderId] = sender;
      } catch (e) {
        // If fetching fails, continue without sender info
        print('Failed to fetch sender $senderId: $e');
      }
    }

    // Create new list with messages that have sender information populated
    return messages.map((message) {
      if (message.sender == null && message.senderId.isNotEmpty) {
        final sender = _senderCache[message.senderId];
        if (sender != null) {
          return ChatMessageModel(
            id: message.id,
            channel: message.channel,
            labId: message.labId,
            senderId: message.senderId,
            sender: sender,
            recipientIds: message.recipientIds,
            recipients: message.recipients,
            content: message.content,
            fileIds: message.fileIds,
            files: message.files,
            createdAt: message.createdAt,
          );
        }
      }
      return message;
    }).toList();
  }

  /// Get message with sender information populated
  Future<ChatMessageModel> _getMessageWithSender(ChatMessageModel message) async {
    if (message.sender != null || message.senderId.isEmpty) {
      return message;
    }

    // Check cache first
    if (_senderCache.containsKey(message.senderId)) {
      final sender = _senderCache[message.senderId]!;
      return ChatMessageModel(
        id: message.id,
        channel: message.channel,
        labId: message.labId,
        senderId: message.senderId,
        sender: sender,
        recipientIds: message.recipientIds,
        recipients: message.recipients,
        content: message.content,
        fileIds: message.fileIds,
        files: message.files,
        createdAt: message.createdAt,
      );
    }

    // Fetch sender information
    try {
      final sender = await UserService.getUserById(message.senderId);
      _senderCache[message.senderId] = sender;
      return ChatMessageModel(
        id: message.id,
        channel: message.channel,
        labId: message.labId,
        senderId: message.senderId,
        sender: sender,
        recipientIds: message.recipientIds,
        recipients: message.recipients,
        content: message.content,
        fileIds: message.fileIds,
        files: message.files,
        createdAt: message.createdAt,
      );
    } catch (e) {
      // If fetching fails, return message without sender info
      print('Failed to fetch sender ${message.senderId}: $e');
      return message;
    }
  }
}
