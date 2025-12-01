import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<AttendanceModel> attendanceHistory = [];

  Future<void> loadAttendance() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      attendanceHistory = await AttendanceService.getStudentAttendance();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitAttendance(String qrToken) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await AttendanceService.submitAttendance(qrToken);
      isLoading = false;
      notifyListeners();
      await loadAttendance(); // Refresh list
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}


