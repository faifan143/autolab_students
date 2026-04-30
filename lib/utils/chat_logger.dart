/// Chat Logger Utility
/// Provides comprehensive logging for chat system
class ChatLogger {
  static bool _enabled = true;
  static ChatLogLevel _minLevel = ChatLogLevel.debug;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static void setMinLevel(ChatLogLevel level) {
    _minLevel = level;
  }

  static void _log(ChatLogLevel level, String message, [Map<String, dynamic>? data]) {
    if (!_enabled || level.index < _minLevel.index) return;

    final prefix = _getLevelPrefix(level);
    final timestamp = DateTime.now().toIso8601String();
    
    print('[$timestamp] $prefix $message');
    if (data != null && data.isNotEmpty) {
      data.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }

  static String _getLevelPrefix(ChatLogLevel level) {
    switch (level) {
      case ChatLogLevel.debug:
        return '🐛 DEBUG';
      case ChatLogLevel.info:
        return 'ℹ️  INFO';
      case ChatLogLevel.warning:
        return '⚠️  WARN';
      case ChatLogLevel.error:
        return '❌ ERROR';
    }
  }

  // Connection logging
  static void logConnectionAttempt(String uri, [String? tokenPreview]) {
    _log(ChatLogLevel.debug, 'Connection attempt', {
      'uri': uri,
      if (tokenPreview != null) 'token': tokenPreview,
    });
  }

  static void logConnectionSuccess([String? socketId]) {
    _log(ChatLogLevel.info, 'Connection established', {
      if (socketId != null) 'socketId': socketId,
    });
  }

  static void logDisconnection([String? reason]) {
    _log(ChatLogLevel.warning, 'Disconnected', {
      if (reason != null) 'reason': reason,
    });
  }

  static void logConnectionError(dynamic error) {
    _log(ChatLogLevel.error, 'Connection error', {
      'error': error.toString(),
    });
  }

  static void logConnectionTimeout() {
    _log(ChatLogLevel.error, 'Connection timeout');
  }

  // Channel logging
  static void logChannelJoinAttempt(String channel, [String? labId]) {
    _log(ChatLogLevel.debug, 'Joining channel', {
      'channel': channel,
      if (labId != null) 'labId': labId,
    });
  }

  static void logChannelJoined(String channel, [String? labId]) {
    _log(ChatLogLevel.info, 'Channel joined', {
      'channel': channel,
      if (labId != null) 'labId': labId,
    });
  }

  static void logChannelLeft(String channel) {
    _log(ChatLogLevel.info, 'Channel left', {'channel': channel});
  }

  static void logChannelJoinError(String channel, dynamic error) {
    _log(ChatLogLevel.error, 'Channel join error', {
      'channel': channel,
      'error': error.toString(),
    });
  }

  // Message logging
  static void logMessageSend(String channel, String? content, [String? labId, List<String>? fileIds]) {
    _log(ChatLogLevel.debug, 'Sending message', {
      'channel': channel,
      if (labId != null) 'labId': labId,
      if (content != null) 'content': content.length > 50 ? '${content.substring(0, 50)}...' : content,
      if (fileIds != null) 'fileCount': fileIds.length,
    });
  }

  static void logMessageSent(String messageId, String channel) {
    _log(ChatLogLevel.info, 'Message sent', {
      'messageId': messageId,
      'channel': channel,
    });
  }

  static void logMessageReceived(String messageId, String channel, String senderId, [String? senderName, String? content, String? labId, List<String>? fileIds]) {
    _log(ChatLogLevel.info, 'Message received', {
      'messageId': messageId,
      'channel': channel,
      'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (content != null) 'content': content.length > 50 ? '${content.substring(0, 50)}...' : content,
      if (labId != null) 'labId': labId,
      if (fileIds != null) 'fileCount': fileIds.length,
    });
  }

  static void logMessageFetch(String? channel, [String? labId, int? limit, int? offset, int? messageCount]) {
    _log(ChatLogLevel.debug, 'Fetching messages', {
      'channel': channel,
      if (labId != null) 'labId': labId,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (messageCount != null) 'messageCount': messageCount,
    });
  }

  static void logMessageFetchError(String channel, dynamic error) {
    _log(ChatLogLevel.error, 'Message fetch error', {
      'channel': channel,
      'error': error.toString(),
    });
  }

  static void logMessageSendError(String channel, dynamic error) {
    _log(ChatLogLevel.error, 'Message send error', {
      'channel': channel,
      'error': error.toString(),
    });
  }

  static void logMessageParseError(dynamic error, [dynamic rawData]) {
    _log(ChatLogLevel.error, 'Message parse error', {
      'error': error.toString(),
      if (rawData != null) 'rawData': rawData.toString(),
    });
  }

  // File logging
  static void logFileSelected(String fileName, int fileSize, String mimeType) {
    _log(ChatLogLevel.debug, 'File selected', {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
    });
  }

  static void logFileUploadStart(String fileName, [String? labId]) {
    _log(ChatLogLevel.info, 'File upload start', {
      'fileName': fileName,
      if (labId != null) 'labId': labId,
    });
  }

  static void logFileUploadSuccess(String fileName, String fileId) {
    _log(ChatLogLevel.info, 'File upload success', {
      'fileName': fileName,
      'fileId': fileId,
    });
  }

  static void logFileUploadError(String fileName, dynamic error) {
    _log(ChatLogLevel.error, 'File upload error', {
      'fileName': fileName,
      'error': error.toString(),
    });
  }

  // State logging
  static void logProviderInit(String channel, [String? labId]) {
    _log(ChatLogLevel.info, 'Provider initialized', {
      'channel': channel,
      if (labId != null) 'labId': labId,
    });
  }

  static void logError(String category, dynamic error, [Map<String, dynamic>? context]) {
    _log(ChatLogLevel.error, 'Error: $category', {
      'error': error.toString(),
      if (context != null) ...context,
    });
  }

  static void logWarning(String category, String message, [Map<String, dynamic>? context]) {
    _log(ChatLogLevel.warning, 'Warning: $category', {
      'message': message,
      if (context != null) ...context,
    });
  }

  static void debug(String message, [Map<String, dynamic>? data]) {
    _log(ChatLogLevel.debug, message, data);
  }

  static void info(String message, [Map<String, dynamic>? data]) {
    _log(ChatLogLevel.info, message, data);
  }
}

enum ChatLogLevel {
  debug,
  info,
  warning,
  error,
}

