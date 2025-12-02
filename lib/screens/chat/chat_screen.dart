import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _labId;

  @override
  void initState() {
    super.initState();
    // Get labId from navigation arguments
    _labId = Get.arguments as String?;
    if (_labId == null) {
      // If no labId provided, try to get from home screen context
      // For now, show error if no labId
      _labId = null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _labId == null) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(_messageController.text.trim());
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    if (_labId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (chatProvider.currentLabId != _labId) {
          chatProvider.initializeChat(_labId!);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'chat'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _labId == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'chat_no_lab_selected'.tr,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Get.back(),
                            child: Text('go_back'.tr),
                          ),
                        ],
                      ),
                    )
                  : chatProvider.isLoading && chatProvider.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : chatProvider.messages.isEmpty
                          ? Center(child: Text('no_messages'.tr))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: chatProvider.messages.length,
                              itemBuilder: (context, index) {
                                final message = chatProvider.messages[index];
                                return _ChatBubble(message: message);
                              },
                            ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'type_message'.tr,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.senderName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(message.content),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
