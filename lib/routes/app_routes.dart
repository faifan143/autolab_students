import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/labs/labs_list_screen.dart';
import '../screens/labs/lab_detail_screen.dart';
import '../screens/sessions/sessions_list_screen.dart';
import '../screens/sessions/session_detail_screen.dart';
import '../screens/sessions/session_streaming_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/attendance/student_qr_screen.dart';
import '../screens/grades/grades_list_screen.dart';
import '../screens/files/files_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/complaints/complaints_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String labs = '/labs';
  static const String labDetail = '/labs/detail';
  static const String sessions = '/sessions';
  static const String sessionDetail = '/sessions/detail';
  static const String sessionStreaming = '/sessions/streaming';
  static const String attendance = '/attendance';
  static const String studentQr = '/attendance/student-qr';
  static const String grades = '/grades';
  static const String files = '/files';
  static const String chat = '/chat';
  static const String complaints = '/complaints';
  static const String settings = '/settings';

  static final List<GetPage<dynamic>> getPages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: labs, page: () => const LabsListScreen()),
    GetPage(name: labDetail, page: () => const LabDetailScreen()),
    GetPage(name: sessions, page: () => const SessionsListScreen()),
    GetPage(name: sessionDetail, page: () => const SessionDetailScreen()),
    GetPage(
        name: sessionStreaming,
        page: () => const SessionStreamingScreen()),
    GetPage(name: attendance, page: () => const AttendanceScreen()),
    GetPage(name: studentQr, page: () => const StudentQrScreen()),
    GetPage(name: grades, page: () => const GradesListScreen()),
    GetPage(name: files, page: () => const FilesListScreen()),
    GetPage(name: chat, page: () => const ChatScreen()),
    GetPage(name: complaints, page: () => const ComplaintsScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
  ];
}


