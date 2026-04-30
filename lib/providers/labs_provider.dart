import 'package:flutter/foundation.dart';
import '../models/lab_model.dart';
import '../models/user_model.dart';
import '../services/labs_service.dart';
import '../services/user_service.dart';

class LabsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isEnrolling = false;
  String? error;
  List<LabModel> enrolledLabs = [];
  List<LabModel> availableLabs = [];
  // Cache for teacher information by teacherId
  final Map<String, UserModel> _teacherCache = {};

  Future<void> loadLabs() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Load both enrolled and available labs in parallel
      final results = await Future.wait([
        LabsService.getStudentLabs(),
        LabsService.getAvailableLabs(),
      ]);

      enrolledLabs = results[0];
      availableLabs = results[1];

      // Fetch teacher information for all unique teacher IDs
      await _loadTeacherInfo();

      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e, stackTrace) {
      error = e.toString();
      isLoading = false;
      print('Error loading labs: $e');
      print('Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  /// Load teacher information for all unique teacher IDs in the labs
  Future<void> _loadTeacherInfo() async {
    // Collect all unique teacher IDs
    final Set<String> teacherIds = {};
    for (final lab in enrolledLabs) {
      if (lab.teacherId != null) {
        teacherIds.add(lab.teacherId!);
      }
    }
    for (final lab in availableLabs) {
      if (lab.teacherId != null) {
        teacherIds.add(lab.teacherId!);
      }
    }

    // Fetch teacher info for all unique IDs (in parallel)
    final List<Future<void>> futures = [];
    for (final teacherId in teacherIds) {
      // Skip if already cached
      if (_teacherCache.containsKey(teacherId)) continue;

      futures.add(
        UserService.getUserById(teacherId)
            .then((teacher) {
              _teacherCache[teacherId] = teacher;
              // Notify listeners when each teacher is loaded to update UI
              notifyListeners();
            })
            .catchError((e) {
              // Silently fail for individual teacher fetches
              print('Failed to load teacher $teacherId: $e');
            }),
      );
    }

    // Wait for all teacher info to load (with timeout)
    await Future.wait(futures, eagerError: false);
  }

  /// Get teacher name by teacherId, returns cached name or fallback
  String getTeacherName(String? teacherId) {
    if (teacherId == null) return 'Unknown Teacher';
    final teacher = _teacherCache[teacherId];
    return teacher?.name ?? 'Loading...';
  }

  Future<bool> enrollInLab(String labId) async {
    isEnrolling = true;
    error = null;
    notifyListeners();

    try {
      await LabsService.enrollInLab(labId);
      // Reload labs to reflect enrollment
      await loadLabs();
      isEnrolling = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isEnrolling = false;
      notifyListeners();
      return false;
    }
  }

  // Helper getter for backward compatibility
  List<LabModel> get labs => enrolledLabs;
}
