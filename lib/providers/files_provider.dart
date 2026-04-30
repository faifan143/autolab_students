import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_model.dart';
import '../services/files_service.dart';

class FilesProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isDownloading = false;
  String? error;
  List<FileModel> files = [];

  Future<void> loadFiles({String? labId, String? sessionId}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      files = await FilesService.getFiles(labId: labId, sessionId: sessionId);
      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getFileDownloadUrl(String fileId) async {
    try {
      return await FilesService.getFileDownloadUrl(fileId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> getFileUrl(FileModel file) async {
    return await FilesService.getFileUrl(file.id);
  }

  Future<File?> downloadFile(FileModel file) async {
    isDownloading = true;
    error = null;
    notifyListeners();

    try {
      final downloadedFile = await FilesService.downloadFile(
        file.id,
        file.fileName,
      );
      isDownloading = false;
      notifyListeners();
      return downloadedFile;
    } catch (e) {
      error = e.toString();
      isDownloading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload a file
  /// Returns the uploaded FileModel with the file ID
  Future<FileModel?> uploadFile(
    File file, {
    String? labId,
    String? sessionId,
    String? description,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final uploadedFile = await FilesService.uploadFile(
        file,
        labId: labId,
        sessionId: sessionId,
        description: description,
      );
      isLoading = false;
      error = null;
      notifyListeners();
      return uploadedFile;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
