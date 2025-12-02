/// API endpoint constants for the AutoLab Student app
class ApiEndpoints {
  // Base URL will be set dynamically via IP configuration
  static const String defaultBaseUrl = 'http://192.168.0.11:3000';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';

  // Student labs
  static const String studentLabs = '/students/labs';
  static String enrollInLab(String labId) => '/students/labs/$labId/enroll';

  // Sessions
  static String labSessions(String labId) => '/labs/$labId/sessions';
  static String session(String sessionId) => '/sessions/$sessionId';

  // Attendance
  static const String studentAttendance = '/students/attendance';
  static const String submitAttendance = '/attendance/submit';

  // Grades
  static const String studentGrades = '/students/grades';
  static String labGrades(String labId) => '/students/grades/$labId';

  // Files
  static const String files = '/files';
  static String file(String id) => '/files/$id';
  static String fileDownloadUrl(String id) => '/files/$id/download-url';

  // Chat
  static const String chatMessages = '/chat/messages';

  // WebSocket
  static const String wsStudents = '/ws/students';

  // Streaming (student only watches, no start/stop)
  static String sessionStream(String sessionId) => '/sessions/$sessionId';
}
