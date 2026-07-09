import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/api_error_utils.dart';

class AttendanceProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<AttendanceModel> attendanceHistory = [];
  String? checkInToken;
  DateTime? checkInExpiresAt;

  Future<void> loadAttendance() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      attendanceHistory = await AttendanceService.getStudentAttendance();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = ApiErrorUtils.message(e, fallback: 'Failed to load attendance');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadCheckInQr(String sessionId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await AttendanceService.getMyCheckInQr(sessionId);
      checkInToken = response.token;
      checkInExpiresAt = DateTime.tryParse(response.expiresAt);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiErrorUtils.message(
        e,
        fallback: 'Could not load attendance QR',
      );
      checkInToken = null;
      checkInExpiresAt = null;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
