import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import '../../providers/files_provider.dart';
import '../../models/file_model.dart';
import '../../services/files_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../widgets/app_cards.dart';

class FilesListScreen extends StatefulWidget {
  const FilesListScreen({super.key});

  @override
  State<FilesListScreen> createState() => _FilesListScreenState();
}

class _FilesListScreenState extends State<FilesListScreen> {
  bool _hasInitialized = false;
  String? _labId;
  String? _sessionId;
  String? _labName;

  @override
  void initState() {
    super.initState();
    // Extract labId from navigation arguments
    final args = Get.arguments;
    if (args is String) {
      _labId = args;
    } else if (args is Map<String, dynamic>) {
      _labId = args['labId'] as String?;
      _sessionId = args['sessionId'] as String?;
      _labName = args['labName'] as String?;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        final filesProvider = Provider.of<FilesProvider>(
          context,
          listen: false,
        );
        if (filesProvider.files.isEmpty && !filesProvider.isLoading) {
          filesProvider.loadFiles(labId: _labId, sessionId: _sessionId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filesProvider = Provider.of<FilesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(_screenTitle()),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: filesProvider.isLoading && filesProvider.files.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filesProvider.files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('no_files'.tr),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                filesProvider.loadFiles(
                                  labId: _labId,
                                  sessionId: _sessionId,
                                ),
                            child: Text('retry'.tr),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => filesProvider.loadFiles(
                        labId: _labId,
                        sessionId: _sessionId,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filesProvider.files.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = filesProvider.files[index];
                          return _FileCard(
                            file: file,
                            displayName: _displayFileName(file),
                            onTap: () => _showFileDetails(
                              context,
                              file,
                              filesProvider,
                            ),
                            onOpen: () => _openFile(context, file, filesProvider),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _screenTitle() {
    if (_sessionId != null && _sessionId!.isNotEmpty) {
      return '${'files'.tr} • ${'sessions'.tr}';
    }
    if (_labName != null && _labName!.isNotEmpty) {
      return '${'files'.tr} • $_labName';
    }
    if (_labId != null && _labId!.isNotEmpty) {
      return '${'files'.tr} • ${'labs'.tr}';
    }
    return 'files'.tr;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showFileDetails(
    BuildContext context,
    FileModel file,
    FilesProvider provider,
  ) async {
    await Get.bottomSheet(
      SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'file_details'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
            _DetailRow('file_name'.tr, _displayFileName(file)),
                _DetailRow('file_size'.tr, _formatFileSize(file.size)),
                _DetailRow(
                  'created_at'.tr,
                  file.createdAt != null
                      ? DateFormat('MMM dd, yyyy HH:mm').format(file.createdAt!)
                      : 'unknown'.tr,
                ),
                const SizedBox(height: 16),
                // Show different buttons for images vs other files
                if (FilesService.isImageFile(file.mimeType) ||
                    FilesService.isImageFileByName(file.fileName))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Get.back(); // Close bottom sheet
                        await _showImagePreview(context, file, provider);
                      },
                      icon: const Icon(Icons.image),
                      label: Text('view_image'.tr),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isDownloading
                          ? null
                          : () async {
                              await _downloadAndOpenFile(context, file, provider);
                            },
                      icon: provider.isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        provider.isDownloading
                            ? 'downloading'.tr
                            : 'download_and_open'.tr,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayFileName(FileModel file) {
    var name = file.fileName.trim();
    if (name.isEmpty) return 'file_name'.tr;

    if (name.startsWith('session_stream_')) {
      final dot = name.lastIndexOf('.');
      final ext = dot >= 0 ? name.substring(dot) : '';
      return '${'session_recording'.tr}$ext';
    }

    final withDashPrefix = RegExp(r'^[a-zA-Z0-9_-]{16,}[-_](.+)$');
    final match = withDashPrefix.firstMatch(name);
    if (match != null && match.groupCount >= 1) {
      name = match.group(1) ?? name;
    }

    if (name.startsWith('-') && name.contains('.')) {
      final ext = name.substring(name.lastIndexOf('.'));
      return '${'file_name'.tr}$ext';
    }

    return name.replaceAll('_', ' ');
  }

  Future<void> _openFile(
    BuildContext context,
    FileModel file,
    FilesProvider provider,
  ) async {
    if (FilesService.isImageFile(file.mimeType) ||
        FilesService.isImageFileByName(file.fileName)) {
      await _showImagePreview(context, file, provider);
      return;
    }

    if (provider.isDownloading) return;

    final downloaded = await provider.downloadFile(file);
    if (!context.mounted) return;

    if (downloaded == null) {
      Get.snackbar(
        'error'.tr,
        provider.error ?? 'download_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final result = await OpenFilex.open(downloaded.path);
    if (!context.mounted) return;

    if (result.type != ResultType.done) {
      Get.snackbar(
        'warning'.tr,
        'no_app_to_open_file'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _downloadAndOpenFile(
    BuildContext context,
    FileModel file,
    FilesProvider provider,
  ) async {
    try {
      // Downloads are saved into app-specific temporary storage, which does
      // not require runtime storage permission on modern Android versions.

      // Download file
      final downloadedFile = await provider.downloadFile(file);

      if (downloadedFile == null) {
        Get.snackbar(
          'error'.tr,
          provider.error ?? 'download_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Close bottom sheet
      Get.back();

      // Open file with external app
      final result = await OpenFilex.open(downloadedFile.path);

      if (result.type != ResultType.done) {
        Get.snackbar(
          'warning'.tr,
          'no_app_to_open_file'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _showImagePreview(
    BuildContext context,
    FileModel file,
    FilesProvider provider,
  ) async {
    try {
      // Get file URL
      final fileUrl = await provider.getFileUrl(file);

      // Get access token for image headers
      final token = await StorageService.getAccessToken();
      final headers = token != null
          ? {'Authorization': 'Bearer $token'}
          : <String, String>{};

      // Show image in full screen viewer
      Get.to(
        () => _ImageViewerScreen(
          imageUrl: fileUrl,
          fileName: file.fileName,
          headers: headers,
        ),
        fullscreenDialog: true,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}

class _FileCard extends StatelessWidget {
  final FileModel file;
  final String displayName;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  const _FileCard({
    required this.file,
    required this.displayName,
    required this.onTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

    return AppSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          const AppIconBadge(icon: Icons.insert_drive_file),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  file.createdAt == null
                      ? _formatSize(file.size)
                      : '${_formatSize(file.size)} • ${formatter.format(file.createdAt!.toLocal())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'download_and_open'.tr,
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;
  final Map<String, String> headers;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.fileName,
    this.headers = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(fileName, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: headers.isNotEmpty
              ? _AuthenticatedImageProvider(imageUrl, headers)
              : CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text('error'.tr, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom ImageProvider that supports authentication headers
class _AuthenticatedImageProvider
    extends ImageProvider<_AuthenticatedImageProvider> {
  final String url;
  final Map<String, String> headers;

  const _AuthenticatedImageProvider(this.url, this.headers);

  @override
  Future<_AuthenticatedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _AuthenticatedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
    _AuthenticatedImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final dio = await ApiService.dio;
      final response = await dio.get(
        key.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: key.headers,
        ),
      );

      if (response.statusCode == 200 && response.data is List<int>) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading image: $e');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AuthenticatedImageProvider &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
