import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/locale_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ip_config_dialog.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(theme: theme),
          const SizedBox(height: 16),
          Text('account_section'.tr, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('profile_details'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                Obx(
                  () => ListTile(
                    leading: const Icon(Icons.language),
                    title: Text('language'.tr),
                    subtitle: Text(localeController.locale.value.languageCode.toUpperCase()),
                    trailing: DropdownButton<String>(
                      value: localeController.locale.value.languageCode,
                      underline: const SizedBox.shrink(),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('app_section'.tr, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                Obx(
                  () => ListTile(
                    leading: Icon(
                      themeController.themeMode.value == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: Text('theme'.tr),
                    subtitle: Text(
                      themeController.themeMode.value == ThemeMode.dark
                          ? 'theme_dark'.tr
                          : 'theme_light'.tr,
                    ),
                    trailing: Switch(
                      value: themeController.themeMode.value == ThemeMode.dark,
                      onChanged: (_) => themeController.toggleTheme(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                FutureBuilder<String>(
                  future: _getServerInfo(),
                  builder: (context, snapshot) {
                    return ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: Text('server_ip'.tr),
                      subtitle: Text(snapshot.data ?? 'loading'.tr),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const IpConfigDialog(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('about_section'.tr, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('about_app'.tr),
                  subtitle: Text('about_app_description'.tr),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text('privacy_policy'.tr),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _LogoutButton(theme: theme),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final name = user?.name ?? 'student'.tr;
    final email = user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                Text(
                  'role_student'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.logout),
      label: Text('logout'.tr),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.logout, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('logout_title'.tr),
                ],
              ),
              content: Text('logout_message'.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('cancel'.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: Text('logout'.tr),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.logout();
        }
      },
    );
  }
}
