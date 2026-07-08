import '../models/lab_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class LabsService {
  /// Enrolled labs for the current student (`GET /labs`).
  /// Backend filters to labs where the student is in `students`.
  static Future<List<LabModel>> getStudentLabs() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.enrolledLabs);

    final List<dynamic> data = response.data;
    return data.map((json) => LabModel.fromJson(json)).toList();
  }

  /// Single lab (`GET /labs/:id`) — student must be enrolled.
  static Future<LabModel> getLab(String labId) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.lab(labId));
    return LabModel.fromJson(response.data);
  }
}
