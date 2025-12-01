import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../services/sessions_service.dart';

class SessionsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<SessionModel> sessions = [];
  SessionModel? currentSession;

  Future<void> loadLabSessions(String labId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      sessions = await SessionsService.getLabSessions(labId);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSession(String sessionId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      currentSession = await SessionsService.getSession(sessionId);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}


