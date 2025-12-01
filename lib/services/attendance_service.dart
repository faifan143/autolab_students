import '../models/attendance_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class AttendanceService {
  /// Get attendance history for the current student
  static Future<List<AttendanceModel>> getStudentAttendance() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.studentAttendance);
    
    final List<dynamic> data = response.data;
    return data.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  /// Submit attendance via QR token
  static Future<void> submitAttendance(String qrToken) async {
    final dio = await ApiService.dio;
    await dio.post(
      ApiEndpoints.submitAttendance,
      data: {'token': qrToken},
    );
  }
}

