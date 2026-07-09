import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class FilesService {
  /// Get all shared files with optional filtering
  static Future<List<FileModel>> getFiles({
    String? labId,
    String? sessionId,
  }) async {
    final dio = await ApiService.dio;
    final queryParams = <String, dynamic>{};
    if (labId != null) queryParams['labId'] = labId;
    if (sessionId != null) queryParams['sessionId'] = sessionId;

    final response = await dio.get(
      ApiEndpoints.files,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => FileModel.fromJson(json)).toList();
  }

  /// Get a specific file by ID
  static Future<FileModel> getFile(String id) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.file(id));

    return FileModel.fromJson(response.data);
  }

  /// Get presigned download URL for a file
  /// This is the correct way to get file URLs according to the API documentation
  static Future<String> getFileDownloadUrl(String id) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.fileDownloadUrl(id));

    if (response.data is Map && response.data.containsKey('url')) {
      return response.data['url'] as String;
    } else {
      throw Exception('Invalid response format: missing url field');
    }
  }

  /// Get file URL for viewing (for images) or downloading
  /// Uses presigned URL from the API
  static Future<String> getFileUrl(String fileId) async {
    return await getFileDownloadUrl(fileId);
  }

  /// Check if file is an image based on MIME type
  static bool isImageFile(String mimeType) {
    return mimeType.startsWith('image/');
  }

  /// Check if file is an image based on file name (fallback)
  static bool isImageFileByName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
    ].contains(extension);
  }

  /// Download file and save it to temporary directory
  /// Uses presigned URL from the API
  static Future<File> downloadFile(String fileId, String fileName) async {
    try {
      // Get temporary directory for downloads
      final directory = await getTemporaryDirectory();
      final downloadDir = Directory('${directory.path}/downloads');

      // Create downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Create a safe local filename so files always open reliably.
      final safeName = _safeLocalFileName(fileId, fileName);
      final filePath = '${downloadDir.path}/$safeName';
      final file = File(filePath);

      // Get presigned download URL from API
      final presignedUrl = await getFileDownloadUrl(fileId);

      // Download file using presigned URL (no auth headers needed for presigned URLs)
      final dio =
          Dio(); // Use new Dio instance without interceptors for presigned URL
      final response = await dio.download(
        presignedUrl,
        filePath,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return file;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  static String _safeLocalFileName(String fileId, String fileName) {
    final normalized = fileName.trim().isEmpty ? 'file' : fileName.trim();
    final sanitized = normalized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$fileId-$sanitized';
  }

  /// Upload a file
  /// Returns the uploaded FileModel with the file ID
  static Future<FileModel> uploadFile(
    File file, {
    String? labId,
    String? sessionId,
    String? description,
  }) async {
    try {
      final dio = await ApiService.dio;
      final fileName = file.path.split('/').last;

      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        if (labId != null) 'labId': labId,
        if (sessionId != null) 'sessionId': sessionId,
        if (description != null) 'description': description,
      });

      final response = await dio.post(
        ApiEndpoints.files,
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      return FileModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }
}
