import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../routes/app_routes.dart';

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

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // TODO: Send token to backend for registration
        print('FCM Token: $token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        // TODO: Update token on backend
        print('New FCM Token: $newToken');
      });

      _initialized = true;
    }
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'AutoLab',
        body: notification.body ?? '',
        data: data,
      );
    }
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

    switch (type) {
      case 'LAB_ENROLLMENT':
        // Navigate to labs screen
        AppRoutes.navigatorKey.currentState?.pushNamed(AppRoutes.labs);
        break;
      case 'SESSION_STARTED':
      case 'SESSION_ENDED':
        // Navigate to sessions screen
        final labId = data['labId'] as String?;
        if (labId != null) {
          AppRoutes.navigatorKey.currentState?.pushNamed(
            AppRoutes.sessions,
            arguments: labId,
          );
        } else {
          AppRoutes.navigatorKey.currentState?.pushNamed(AppRoutes.sessions);
        }
        break;
      default:
        // Navigate to home
        AppRoutes.navigatorKey.currentState?.pushNamed(AppRoutes.home);
    }
  }

  /// Get FCM token for backend registration
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  print('Handling background message: ${message.messageId}');
}
