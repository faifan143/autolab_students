import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HomeTile('my_labs'.tr, Icons.school, AppRoutes.labs),
      _HomeTile('sessions'.tr, Icons.event, AppRoutes.sessions),
      _HomeTile('attendance'.tr, Icons.qr_code, AppRoutes.attendance),
      _HomeTile('grades'.tr, Icons.grade, AppRoutes.grades),
      _HomeTile('files'.tr, Icons.insert_drive_file, AppRoutes.files),
      _HomeTile('chat'.tr, Icons.chat, AppRoutes.chat),
      _HomeTile('settings'.tr, Icons.settings, AppRoutes.settings),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('home_dashboard'.tr),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: tiles.length,
        itemBuilder: (_, index) {
          final tile = tiles[index];
          return Card(
            child: InkWell(
              onTap: () => Get.toNamed(tile.route),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tile.icon, size: 32),
                    const SizedBox(height: 8),
                    Text(tile.title),
                  ],
                ),
              ),
            ),
          );
        },
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


