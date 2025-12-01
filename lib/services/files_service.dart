import '../models/file_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class FilesService {
  /// Get all shared files
  static Future<List<FileModel>> getFiles() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.files);
    
    final List<dynamic> data = response.data;
    return data.map((json) => FileModel.fromJson(json)).toList();
  }

  /// Get a specific file by ID
  static Future<FileModel> getFile(String id) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.file(id));
    
    return FileModel.fromJson(response.data);
  }

  /// Get download URL for a file
  static Future<String> getFileDownloadUrl(String id) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.fileDownloadUrl(id));
    
    return response.data['url'] as String;
  }
}

