import '../models/grade_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class GradesService {
  /// Get all grades for the authenticated user (current student)
  /// Optionally filter by labId
  static Future<List<GradeModel>> getMyGrades({String? labId}) async {
    final dio = await ApiService.dio;
    final queryParams = labId != null ? {'labId': labId} : null;

    final response = await dio.get(
      ApiEndpoints.myGrades,
      queryParameters: queryParams,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => GradeModel.fromJson(json)).toList();
  }

  /// Get all grades for the current student (legacy method)
  @Deprecated('Use getMyGrades() instead')
  static Future<List<GradeModel>> getStudentGrades() async {
    return getMyGrades();
  }

  /// Get grades for a specific lab (legacy method)
  @Deprecated('Use getMyGrades(labId: labId) instead')
  static Future<List<GradeModel>> getLabGrades(String labId) async {
    return getMyGrades(labId: labId);
  }
}
