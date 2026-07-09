/// API endpoint constants for the AutoLab Student app.
/// Aligned with backend routes in `E:/autolab/backend` (NestJS).
class ApiEndpoints {
  // Base URL will be set dynamically via IP configuration
  static const String defaultBaseUrl = 'http://192.168.0.11:3000';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';

  // Labs — students only see enrolled labs via GET /labs
  // There is no /students/labs and no student self-enroll on the backend.
  static const String enrolledLabs = '/labs';
  static String lab(String labId) => '/labs/$labId';

  // Sessions
  static String labSessions(String labId) => '/labs/$labId/sessions';
  static String session(String sessionId) => '/sessions/$sessionId';

  // Attendance
  static const String studentAttendance = '/attendance/me';
  static String myCheckInQr(String sessionId) =>
      '/attendance/sessions/$sessionId/my-qr';

  // Grades
  static const String myGrades = '/grades/me';
  static String labGrades(String labId) => '/grades/labs/$labId';

  // Files
  static const String files = '/files';
  static String file(String id) => '/files/$id';
  static String fileDownloadUrl(String id) => '/files/$id/url';

  // Chat
  static const String chatMessages = '/chat/messages';

  // Complaints
  static const String complaints = '/complaints';
  static const String myComplaints = '/complaints/me';

  // WebSocket
  static const String wsStudents = '/ws/students';

  // Streaming (student only watches, no start/stop)
  static String sessionStream(String sessionId) => '/sessions/$sessionId';

  // Users — students may only view their own profile (`GET /users/:id`)
  static String user(String userId) => '/users/$userId';
}
