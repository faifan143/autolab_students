import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

/// Firebase Cloud Messaging service for handling push notifications
class FirebaseNotificationsService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize FCM and local notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'autolab_students_channel',
        'AutoLab Notifications',
        description: 'Notifications for lab enrollment, sessions, and updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is terminated)
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Get FCM token and register with backend
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await registerFCMToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await registerFCMToken(newToken);
      });

      _initialized = true;
    }
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Show local notification
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'AutoLab',
        body: notification.body ?? '',
        data: data,
      );
    }

    // Also handle navigation for foreground messages
    // This allows immediate navigation when app is open
    _handleNotificationNavigation(data);
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'autolab_students_channel',
      'AutoLab Notifications',
      channelDescription:
          'Notifications for lab enrollment, sessions, and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (e) {
        // If payload parsing fails, navigate to home
        AppRoutes.navigatorKey.currentState?.pushNamed(AppRoutes.home);
      }
    }
  }

  /// Handle notification tap when app is in background
  static void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  }

  /// Navigate based on notification type
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final navigator = AppRoutes.navigatorKey.currentState;

    if (navigator == null) return;

    switch (type) {
      case 'LAB_ENROLLMENT':
        // Navigate to labs screen and show success message
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.labs,
          (route) => route.settings.name == AppRoutes.home || route.isFirst,
        );
        // Show success message
        Get.snackbar(
          'enrollment_confirmed'.tr,
          'enrollment_confirmed_message'.tr,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        break;

      case 'LAB_UNENROLLMENT':
        // Navigate to labs screen and show confirmation message
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.labs,
          (route) => route.settings.name == AppRoutes.home || route.isFirst,
        );
        // Show confirmation message
        Get.snackbar(
          'unenrollment_confirmed'.tr,
          'unenrollment_confirmed_message'.tr,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        break;

      case 'SESSION_CREATED':
        // Navigate to sessions screen with labId
        final labId = data['labId'] as String?;
        if (labId != null) {
          navigator.pushNamed(
            AppRoutes.sessions,
            arguments: labId,
          );
        } else {
          navigator.pushNamed(AppRoutes.sessions);
        }
        // Show notification
        Get.snackbar(
          'session_created'.tr,
          'session_created_message'.tr,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        break;

      case 'SESSION_STARTED':
        // Navigate to sessions screen with labId
        final labId = data['labId'] as String?;
        if (labId != null) {
          navigator.pushNamed(
            AppRoutes.sessions,
            arguments: labId,
          );
        } else {
          navigator.pushNamed(AppRoutes.sessions);
        }
        // Show notification
        Get.snackbar(
          'session_started'.tr,
          'session_started_message'.tr,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        break;

      case 'SESSION_UPDATED':
        // Navigate to sessions screen with labId
        final labId = data['labId'] as String?;
        if (labId != null) {
          navigator.pushNamed(
            AppRoutes.sessions,
            arguments: labId,
          );
        } else {
          navigator.pushNamed(AppRoutes.sessions);
        }
        // Show notification
        Get.snackbar(
          'session_updated'.tr,
          'session_updated_message'.tr,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        break;

      case 'SESSION_ENDED':
        // Navigate to sessions screen with labId
        final labId = data['labId'] as String?;
        if (labId != null) {
          navigator.pushNamed(
            AppRoutes.sessions,
            arguments: labId,
          );
        } else {
          navigator.pushNamed(AppRoutes.sessions);
        }
        // Show notification
        Get.snackbar(
          'session_ended'.tr,
          'session_ended_message'.tr,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        break;

      case 'CHAT_MESSAGE':
      case 'NEW_CHAT_MESSAGE': // Support both for backward compatibility
        // Navigate to chat screen with labId
        final labId = data['labId'] as String?;
        final senderName = data['senderName'] as String?;
        final messageContent = data['content'] as String? ?? data['message'] as String?;
        final labName = data['labName'] as String?;
        // Note: messageId, senderId available in data but not used for navigation
        
        if (labId != null) {
          navigator.pushNamed(
            AppRoutes.chat,
            arguments: labId,
          );
          // Show message preview with sender name and lab name
          final title = senderName != null && labName != null
              ? '$senderName in $labName'
              : senderName ?? labName ?? 'new_message'.tr;
          Get.snackbar(
            title,
            messageContent ?? 'new_chat_message'.tr,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );
        } else {
          navigator.pushNamed(AppRoutes.home);
        }
        break;

      default:
        // Navigate to home
        navigator.pushNamed(AppRoutes.home);
    }
  }

  /// Register FCM token with backend
  static Future<void> registerFCMToken(String token) async {
    try {
      final dio = await ApiService.dio;
      await dio.post(
        ApiEndpoints.fcmToken,
        data: {'fcmToken': token},
      );
      print('FCM token registered successfully: $token');
    } catch (e) {
      print('Failed to register FCM token: $e');
      // Don't throw - allow app to continue even if token registration fails
    }
  }

  /// Get FCM token for backend registration
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

/// Background message handler (must be top-level function)
/// This handles notifications when app is terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  // Note: Firebase.initializeApp() should be called in main.dart before this
  
  // Show local notification for background messages
  final notification = message.notification;
  final data = message.data;

  if (notification != null) {
    // Initialize local notifications plugin
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(initSettings);

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'autolab_students_channel',
      'AutoLab Notifications',
      description: 'Notifications for lab enrollment, sessions, and updates',
      importance: Importance.high,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Show notification
    const androidDetails = AndroidNotificationDetails(
      'autolab_students_channel',
      'AutoLab Notifications',
      channelDescription: 'Notifications for lab enrollment, sessions, and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title ?? 'AutoLab',
      notification.body ?? '',
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  print('Handling background message: ${message.messageId}');
}
