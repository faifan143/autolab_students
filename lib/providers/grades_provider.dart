import 'package:flutter/foundation.dart';
import '../models/grade_model.dart';
import '../services/grades_service.dart';

class GradesProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<GradeModel> grades = [];

  Future<void> loadGrades({String? labId}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      if (labId != null) {
        grades = await GradesService.getLabGrades(labId);
      } else {
        grades = await GradesService.getStudentGrades();
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}


