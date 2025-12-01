import 'package:flutter/foundation.dart';
import '../models/file_model.dart';
import '../services/files_service.dart';

class FilesProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<FileModel> files = [];

  Future<void> loadFiles() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      files = await FilesService.getFiles();
      isLoading = false;
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
}


