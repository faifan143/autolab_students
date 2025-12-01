import '../models/lab_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class LabsService {
  /// Get all labs for the current student
  static Future<List<LabModel>> getStudentLabs() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.studentLabs);
    
    final List<dynamic> data = response.data;
    return data.map((json) => LabModel.fromJson(json)).toList();
  }
}

