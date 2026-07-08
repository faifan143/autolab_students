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

  /// Fetch a short-lived QR token for the student to display during a session
  static Future<StudentCheckInQrResponse> getMyCheckInQr(
    String sessionId,
  ) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.myCheckInQr(sessionId));
    return StudentCheckInQrResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
