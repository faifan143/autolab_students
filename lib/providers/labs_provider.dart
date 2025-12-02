import 'package:flutter/foundation.dart';
import '../models/lab_model.dart';
import '../services/labs_service.dart';

class LabsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isEnrolling = false;
  String? error;
  List<LabModel> labs = [];

  Future<void> loadLabs() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      labs = await LabsService.getStudentLabs();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
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
}


