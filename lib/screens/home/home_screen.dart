import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HomeTile('my_labs'.tr, Icons.science_outlined, AppRoutes.labs),
      _HomeTile('sessions'.tr, Icons.event_outlined, AppRoutes.sessions),
      _HomeTile('attendance'.tr, Icons.how_to_reg_outlined, AppRoutes.attendance),
      _HomeTile('grades'.tr, Icons.bar_chart_outlined, AppRoutes.grades),
      _HomeTile('files'.tr, Icons.folder_open_outlined, AppRoutes.files),
      _HomeTile('chat'.tr, Icons.chat_bubble_outline, AppRoutes.chat),
      _HomeTile('settings'.tr, Icons.settings_outlined, AppRoutes.settings),
    ];

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with avatar and notifications
              _HomeTopBar(theme: theme),
              const SizedBox(height: 16),

              // Header / summary card
              _HeaderCard(theme: theme),
              const SizedBox(height: 24),

              // Section title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home_dashboard'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('see_all'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tiles grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (_, index) {
                    final tile = tiles[index];
                    return _HomeTileCard(tile: tile);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name ?? 'student'.tr;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySoft,
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
                'greeting_generic'.tr,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                name,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'today_overview'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'today_overview_subtitle'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile {
  final String title;
  final IconData icon;
  final String route;

  _HomeTile(this.title, this.icon, this.route);
}

class _HomeTileCard extends StatelessWidget {
  const _HomeTileCard({required this.tile});

  final _HomeTile tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(tile.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                tile.icon,
                size: 32,
                color: AppColors.primary,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tile.title,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'tap_to_open'.tr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
