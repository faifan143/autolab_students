import '../models/grade_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class GradesService {
  /// Get all grades for the current student
  static Future<List<GradeModel>> getStudentGrades() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.studentGrades);
    
    final List<dynamic> data = response.data;
    return data.map((json) => GradeModel.fromJson(json)).toList();
  }

  /// Get grades for a specific lab
  static Future<List<GradeModel>> getLabGrades(String labId) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.labGrades(labId));
    
    final List<dynamic> data = response.data;
    return data.map((json) => GradeModel.fromJson(json)).toList();
  }
}

