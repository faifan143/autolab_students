import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../models/lab_model.dart';
import '../../providers/labs_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_cards.dart';

class LabDetailScreen extends StatelessWidget {
  const LabDetailScreen({super.key});

  LabModel? _resolveLab(LabsProvider labsProvider) {
    final args = Get.arguments;
    if (args is LabModel) return args;
    if (args is String) {
      try {
        return labsProvider.enrolledLabs.firstWhere((l) => l.id == args);
      } catch (_) {
        return null;
      }
    }
    if (args is Map<String, dynamic>) {
      final labId = args['labId'] as String?;
      if (labId == null) return null;
      try {
        return labsProvider.enrolledLabs.firstWhere((l) => l.id == labId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final labsProvider = context.watch<LabsProvider>();
    final lab = _resolveLab(labsProvider);

    if (lab == null) {
      return Scaffold(
        appBar: AppBar(title: Text('labs'.tr)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: color.error),
              const SizedBox(height: 12),
              Text('lab_not_found'.tr, style: theme.textTheme.titleSmall),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('go_back'.tr),
              ),
            ],
          ),
        ),
      );
    }

    final instructorName = labsProvider.getTeacherName(
      lab.teacherId,
      fallback: lab.teacherName,
    );

    return Scaffold(
      appBar: AppBar(title: Text(lab.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSurfaceCard(
            child: Row(
              children: [
                AppIconBadge(icon: Icons.science_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lab.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'teacher'.tr}: $instructorName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (lab.description != null && lab.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'description'.tr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lab.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              AppActionCard(
                icon: Icons.event_outlined,
                title: 'sessions'.tr,
                subtitle: 'labs_sessions_subtitle'.tr,
                onTap: () => Get.toNamed(
                  AppRoutes.sessions,
                  arguments: {'labId': lab.id, 'labName': lab.name},
                ),
              ),
              AppActionCard(
                icon: Icons.grade_outlined,
                title: 'grades'.tr,
                subtitle: 'labs_grades_subtitle'.tr,
                onTap: () => Get.toNamed(
                  AppRoutes.grades,
                  arguments: {'labId': lab.id, 'labName': lab.name},
                ),
              ),
              AppActionCard(
                icon: Icons.folder_open_outlined,
                title: 'files'.tr,
                subtitle: 'labs_files_subtitle'.tr,
                onTap: () => Get.toNamed(
                  AppRoutes.files,
                  arguments: {'labId': lab.id, 'labName': lab.name},
                ),
              ),
              AppActionCard(
                icon: Icons.chat_bubble_outline,
                title: 'chat'.tr,
                subtitle: 'labs_chat_subtitle'.tr,
                onTap: () => Get.toNamed(
                  AppRoutes.chat,
                  arguments: {
                    'channel': 'lab:${lab.id}',
                    'labId': lab.id,
                    'labName': lab.name,
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
