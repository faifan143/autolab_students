import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'localization/app_translations.dart';
import 'providers/auth_provider.dart';
import 'providers/labs_provider.dart';
import 'providers/sessions_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/grades_provider.dart';
import 'providers/files_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/streaming_provider.dart';
import 'services/firebase_notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    // Initialize FCM notifications
    await FirebaseNotificationsService.initialize();
  } catch (e) {
    // Firebase initialization failed (e.g., missing google-services.json)
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize GetX controllers
  Get.put(LocaleController());
  Get.put(ThemeController());

  runApp(const AutoLabStudentsApp());
}

class AutoLabStudentsApp extends StatelessWidget {
  const AutoLabStudentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    final themeController = Get.find<ThemeController>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LabsProvider()),
        ChangeNotifierProvider(create: (_) => SessionsProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => GradesProvider()),
        ChangeNotifierProvider(create: (_) => FilesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StreamingProvider()),
      ],
      child: GetMaterialApp(
        navigatorKey: AppRoutes.navigatorKey,
        title: 'app_title'.tr,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        locale: localeController.locale.value,
        fallbackLocale: const Locale('en'),
        translations: AppTranslations(),
        getPages: AppRoutes.getPages,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}
