import '../models/lab_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class LabsService {
  /// Get all labs for the current student (enrolled labs)
  static Future<List<LabModel>> getStudentLabs() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.enrolledLabs);

    final List<dynamic> data = response.data;
    return data.map((json) => LabModel.fromJson(json)).toList();
  }

  /// Get available labs (not enrolled)
  static Future<List<LabModel>> getAvailableLabs() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.studentLabs);
    
    final List<dynamic> data = response.data;
    return data.map((json) => LabModel.fromJson(json)).toList();
  }

  /// Enroll student in a lab
  static Future<void> enrollInLab(String labId) async {
    final dio = await ApiService.dio;
    await dio.post(ApiEndpoints.enrollInLab(labId));
  }
}
