import 'package:flutter/foundation.dart';
import '../models/grade_model.dart';
import '../services/grades_service.dart';

class GradesProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<GradeModel> grades = [];

  /// Load grades for the authenticated user
  /// Optionally filter by labId
  Future<void> loadGrades({String? labId}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      grades = await GradesService.getMyGrades(labId: labId);
      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
