import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/files_provider.dart';
import '../../models/file_model.dart';

class FilesListScreen extends StatelessWidget {
  const FilesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final filesProvider = Provider.of<FilesProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      filesProvider.loadFiles();
    });

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
                                onPressed: () => filesProvider.loadFiles(),
                                child: Text('retry'.tr),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => filesProvider.loadFiles(),
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
                                    '${_formatFileSize(file.size)} • ${DateFormat('MMM dd, yyyy').format(file.createdAt)}',
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () =>
                                      _showFileDetails(context, file, filesProvider),
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
            _DetailRow('created_at'.tr, DateFormat('MMM dd, yyyy HH:mm').format(file.createdAt)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final url = await provider.getFileDownloadUrl(file.id);
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  } catch (e) {
                    Get.snackbar(
                      'error'.tr,
                      e.toString(),
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: Text('open_file'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}


