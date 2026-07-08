import 'package:flutter/foundation.dart';
import '../models/lab_model.dart';
import '../services/labs_service.dart';

class LabsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<LabModel> enrolledLabs = [];

  /// Kept for older UI paths that still reference available labs.
  /// Backend has no "available labs" list for students.
  List<LabModel> get availableLabs => const [];

  Future<void> loadLabs() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      enrolledLabs = await LabsService.getStudentLabs();
      error = null;
      isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      error = e.toString();
      isLoading = false;
      print('Error loading labs: $e');
      print('Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Instructor name for list tiles.
  /// Backend does not expose teacher profiles to students (`GET /users/:id` → 403),
  /// and `/labs` only returns `teacherId`, so we use a stable label.
  String getTeacherName(String? teacherId, {String? fallback}) {
    if (fallback != null &&
        fallback.isNotEmpty &&
        fallback != 'Unknown Teacher' &&
        !fallback.startsWith('Teacher ID:')) {
      return fallback;
    }
    return 'Instructor';
  }

  // Helper getter for backward compatibility
  List<LabModel> get labs => enrolledLabs;
}
