import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:open_filex/open_filex.dart';
import '../../providers/chat_provider.dart';
import '../../providers/files_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_message_model.dart';
import '../../models/file_model.dart';
import '../../services/files_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasText = false;
  final List<File> _selectedFiles = [];
  final List<String> _uploadedFileIds = [];
  bool _isUploading = false;

  String? _channel;
  String? _labId;
  String? _labName;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });

    // Get arguments from route
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _channel = args['channel'] as String?;
      _labId = args['labId'] as String?;
      _labName = args['labName'] as String?;
    }

    // Initialize chat provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_channel != null) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.init(channel: _channel!, labId: _labId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to pick files: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadedFileIds.clear();
    });

    final filesProvider = context.read<FilesProvider>();

    try {
      for (var file in _selectedFiles) {
        final fileModel = await filesProvider.uploadFile(file, labId: _labId);

        if (fileModel != null) {
          _uploadedFileIds.add(fileModel.id);
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to upload files: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();

    if (content.isEmpty && _selectedFiles.isEmpty) return;

    // Upload files if any
    if (_selectedFiles.isNotEmpty) {
      await _uploadFiles();
    }

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(
      content: content.isEmpty ? null : content,
      fileIds: _uploadedFileIds.isEmpty ? null : _uploadedFileIds,
    );

    // Clear input
    _controller.clear();
    setState(() {
      _selectedFiles.clear();
      _uploadedFileIds.clear();
      _hasText = false;
    });

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
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_labName ?? 'chat.title'.tr),
            if (_channel == 'teachers:lobby')
              Text(
                'chat.subtitle.lobby'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: chatProvider.isLoading && chatProvider.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : chatProvider.error != null && chatProvider.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chatProvider.error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_channel != null) {
                                chatProvider.init(
                                  channel: _channel!,
                                  labId: _labId,
                                );
                              }
                            },
                            child: Text('retry'.tr),
                          ),
                        ],
                      ),
                    )
                  : chatProvider.messages.isEmpty
                  ? _EmptyChatView()
                  : _MessagesList(
                      messages: chatProvider.messages,
                      currentUserId: currentUserId,
                      scrollController: _scrollController,
                    ),
            ),

            // Selected Files Preview
            if (_selectedFiles.isNotEmpty)
              _SelectedFilePreview(
                files: _selectedFiles,
                onRemove: _removeFile,
              ),

            // Input Area
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded),
                      onPressed: _isUploading ? null : _pickFiles,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'chat.input.hint'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          enabled: !_isUploading,
                        ),
                        onChanged: (text) {
                          setState(() {
                            _hasText = text.trim().isNotEmpty;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            (_hasText || _selectedFiles.isNotEmpty) &&
                                !_isUploading
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        color:
                            (_hasText || _selectedFiles.isNotEmpty) &&
                                !_isUploading
                            ? Colors.white
                            : null,
                        onPressed:
                            (_hasText || _selectedFiles.isNotEmpty) &&
                                !_isUploading
                            ? _sendMessage
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('chat.empty'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'chat.empty.subtitle'.tr,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<ChatMessageModel> messages;
  final String? currentUserId;
  final ScrollController scrollController;

  const _MessagesList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == currentUserId;
        final showAvatar = _shouldShowAvatar(index);
        final showTimestamp = _shouldShowTimestamp(index);
        final showDateSeparator = _shouldShowDateSeparator(index);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateSeparator) _DateSeparator(date: message.createdAt),
            const SizedBox(height: 8),
            _MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
              showAvatar: showAvatar,
              showTimestamp: showTimestamp,
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowAvatar(int index) {
    if (index == 0) return true;
    final current = messages[index];
    final previous = messages[index - 1];

    if (current.senderId != previous.senderId) return true;

    final timeDiff = current.createdAt.difference(previous.createdAt);
    return timeDiff.inMinutes > 5;
  }

  bool _shouldShowTimestamp(int index) {
    if (index == messages.length - 1) return true;
    final current = messages[index];
    final next = messages[index + 1];

    if (current.senderId != next.senderId) return true;

    final timeDiff = next.createdAt.difference(current.createdAt);
    return timeDiff.inMinutes > 5;
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final current = messages[index];
    final previous = messages[index - 1];

    return !_isSameDay(current.createdAt, previous.createdAt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (_isSameDay(date, today)) {
      dateText = 'Today';
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isCurrentUser;
  final bool showAvatar;
  final bool showTimestamp;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.showAvatar,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showAvatar)
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (!isCurrentUser)
            const SizedBox(width: 36),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  if (!isCurrentUser) const SizedBox(height: 4),
                  if (message.content != null && message.content!.isNotEmpty)
                    Text(
                      message.content!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCurrentUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  if (message.files.isNotEmpty) ...[
                    if (message.content != null && message.content!.isNotEmpty)
                      const SizedBox(height: 8),
                    ...message.files.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _MessageFileAttachment(file: file),
                      ),
                    ),
                  ],
                  if (showTimestamp)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isCurrentUser
                              ? Colors.white70
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _SelectedFilePreview extends StatelessWidget {
  final List<File> files;
  final Function(int) onRemove;

  const _SelectedFilePreview({required this.files, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final fileName = file.path.split('/').last;
          final isImage = FilesService.isImageFileByName(fileName);

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            file,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.insert_drive_file, size: 40),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isImage)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Text(
                      fileName.length > 10
                          ? '${fileName.substring(0, 10)}...'
                          : fileName,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageFileAttachment extends StatefulWidget {
  final FileModel file;

  const _MessageFileAttachment({required this.file});

  @override
  State<_MessageFileAttachment> createState() => _MessageFileAttachmentState();
}

class _MessageFileAttachmentState extends State<_MessageFileAttachment> {
  String? _fileUrl;
  bool _isLoading = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadFileUrl();
  }

  Future<void> _loadFileUrl() async {
    if (widget.file.storageKey.isNotEmpty && _fileUrl == null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final url = await FilesService.getFileDownloadUrl(widget.file.id);
        setState(() {
          _fileUrl = url;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _fileUrl = widget.file.storageKey;
    }
  }

  Future<void> _openFile() async {
    final isImage =
        FilesService.isImageFile(widget.file.mimeType) ||
        FilesService.isImageFileByName(widget.file.fileName);

    if (isImage && _fileUrl != null) {
      // Open image in full screen viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _ImageViewerScreen(
            imageUrl: _fileUrl!,
            fileName: widget.file.fileName,
          ),
        ),
      );
    } else {
      // Download and open other files
      setState(() {
        _isDownloading = true;
      });

      try {
        final downloadedFile = await FilesService.downloadFile(
          widget.file.id,
          widget.file.fileName,
        );

        await OpenFilex.open(downloadedFile.path);
      } catch (e) {
        Get.snackbar('error'.tr, 'Failed to open file: $e');
      } finally {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage =
        FilesService.isImageFile(widget.file.mimeType) ||
        FilesService.isImageFileByName(widget.file.fileName);

    return GestureDetector(
      onTap: _openFile,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: isImage && _fileUrl != null && !_isLoading
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _fileUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _isDownloading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isImage ? Icons.image : Icons.insert_drive_file,
                            size: 24,
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.file.fileName,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.file.size > 0)
                            Text(
                              _formatFileSize(widget.file.size),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const _ImageViewerScreen({required this.imageUrl, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(fileName, style: const TextStyle(color: Colors.white)),
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.covered * 4.0,
      ),
    );
  }
}
