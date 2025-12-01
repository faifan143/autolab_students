import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/locale_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<String> _getServerInfo() async {
    final ip = await StorageService.getServerIp() ?? '192.168.0.11';
    final port = await StorageService.getServerPort() ?? '3000';
    return 'http://$ip:$port';
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('theme'.tr),
            trailing: Obx(
              () => Switch(
                value: themeController.themeMode.value == ThemeMode.dark,
                onChanged: (_) => themeController.toggleTheme(),
              ),
            ),
          ),
          ListTile(
            title: Text('language'.tr),
            trailing: Obx(
              () => DropdownButton<String>(
                value: localeController.locale.value.languageCode,
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('EN'),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text('AR'),
                  ),
                ],
                onChanged: (code) {
                  if (code != null) {
                    localeController.changeLocale(code);
                  }
                },
              ),
            ),
          ),
          FutureBuilder<String>(
            future: _getServerInfo(),
            builder: (context, snapshot) {
              return ListTile(
                title: Text('server_ip'.tr),
                subtitle: Text(snapshot.data ?? 'loading'.tr),
              );
            },
          ),
          ListTile(
            title: Text('logout'.tr),
            leading: const Icon(Icons.logout),
            onTap: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
            },
          ),
        ],
      ),
    );
  }
}


