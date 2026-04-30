import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
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

class FilesListScreen extends StatefulWidget {
  const FilesListScreen({super.key});

  @override
  State<FilesListScreen> createState() => _FilesListScreenState();
}

class _FilesListScreenState extends State<FilesListScreen> {
  bool _hasInitialized = false;
  String? _labId;

  @override
  void initState() {
    super.initState();
    // Extract labId from navigation arguments
    final args = Get.arguments;
    if (args is String) {
      _labId = args;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        final filesProvider = Provider.of<FilesProvider>(
          context,
          listen: false,
        );
        if (filesProvider.files.isEmpty && !filesProvider.isLoading) {
          filesProvider.loadFiles(labId: _labId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filesProvider = Provider.of<FilesProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'files'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
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
                                filesProvider.loadFiles(labId: _labId),
                            child: Text('retry'.tr),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => filesProvider.loadFiles(labId: _labId),
                      child: ListView.builder(
                        itemCount: filesProvider.files.length,
                        itemBuilder: (context, index) {
                          final file = filesProvider.files[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(file.fileName),
                              subtitle: Text(
                                '${_formatFileSize(file.size)} • ${file.createdAt != null ? DateFormat('MMM dd, yyyy').format(file.createdAt!) : 'Unknown date'}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showFileDetails(
                                context,
                                file,
                                filesProvider,
                              ),
                            ),
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
      Container(
        padding: const EdgeInsets.all(16),
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
            _DetailRow('file_name'.tr, file.fileName),
            _DetailRow('file_size'.tr, _formatFileSize(file.size)),
            _DetailRow(
              'created_at'.tr,
              file.createdAt != null
                  ? DateFormat('MMM dd, yyyy HH:mm').format(file.createdAt!)
                  : 'Unknown',
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
    );
  }

  Future<void> _downloadAndOpenFile(
    BuildContext context,
    FileModel file,
    FilesProvider provider,
  ) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar(
            'error'.tr,
            'storage_permission_required'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
          return;
        }
      }

      // Download file
      final downloadedFile = await provider.downloadFile(file);

      if (downloadedFile == null) {
        Get.snackbar(
          'error'.tr,
          provider.error ?? 'download_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
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
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
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
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
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
