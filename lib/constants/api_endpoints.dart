/// API endpoint constants for the AutoLab Student app
class ApiEndpoints {
  // Base URL will be set dynamically via IP configuration
  static const String defaultBaseUrl = 'http://192.168.0.11:3000';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';

  // Student labs
  static const String enrolledLabs = '/labs'; // Get enrolled labs
  static const String studentLabs =
      '/students/labs'; // Get available labs (not enrolled)
  static String enrollInLab(String labId) => '/students/labs/$labId/enroll';
  static String leaveLab(String labId) => '/students/labs/$labId/leave';

  // Sessions
  static String labSessions(String labId) => '/labs/$labId/sessions';
  static String session(String sessionId) => '/sessions/$sessionId';

  // Attendance
  static const String studentAttendance = '/attendance/me';
  static String myCheckInQr(String sessionId) =>
      '/attendance/sessions/$sessionId/my-qr';

  // Grades
  static const String myGrades =
      '/grades/me'; // Get authenticated user's grades
  static const String studentGrades = '/students/grades'; // Legacy endpoint
  static String labGrades(String labId) =>
      '/students/grades/$labId'; // Legacy endpoint

  // Files
  static const String files = '/files';
  static String file(String id) => '/files/$id';
  static String fileDownloadUrl(String id) =>
      '/files/$id/url'; // Presigned download URL

  // Chat
  static const String chatMessages = '/chat/messages';

  // WebSocket
  static const String wsStudents = '/ws/students';

  // Streaming (student only watches, no start/stop)
  static String sessionStream(String sessionId) => '/sessions/$sessionId';

  // FCM Token
  static const String fcmToken = '/students/fcm-token';

  // Users
  static String user(String userId) => '/users/$userId';
}
