import 'package:flutter/foundation.dart';

import '../models/complaint_model.dart';
import '../services/complaints_service.dart';
import '../utils/api_error_utils.dart';

class ComplaintsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isSubmitting = false;
  String? error;
  List<ComplaintModel> complaints = [];

  Future<void> loadMyComplaints() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      complaints = await ComplaintsService.getMyComplaints();
    } catch (e) {
      error = ApiErrorUtils.message(e, fallback: 'Failed to load complaints');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitComplaint({
    required String content,
    bool isAnonymous = false,
    String? labId,
    String? teacherId,
  }) async {
    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      final complaint = await ComplaintsService.createComplaint(
        content: content,
        isAnonymous: isAnonymous,
        labId: labId,
        teacherId: teacherId,
      );
      complaints.insert(0, complaint);
      return true;
    } catch (e) {
      error = ApiErrorUtils.message(e, fallback: 'Failed to submit complaint');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
