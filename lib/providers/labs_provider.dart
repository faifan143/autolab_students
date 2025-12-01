import 'package:flutter/foundation.dart';
import '../models/lab_model.dart';
import '../services/labs_service.dart';

class LabsProvider extends ChangeNotifier {
  bool isLoading = false;
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
}


