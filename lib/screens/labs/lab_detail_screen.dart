import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/lab_model.dart';
import '../../routes/app_routes.dart';
import '../../providers/labs_provider.dart';

class LabDetailScreen extends StatelessWidget {
  const LabDetailScreen({super.key});

  Future<void> _handleEnroll(BuildContext context, String labId) async {
    final labsProvider = context.read<LabsProvider>();
    final success = await labsProvider.enrollInLab(labId);

    if (context.mounted) {
      if (success) {
        Get.snackbar(
          'success'.tr,
          'enrollment_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
        Get.back(); // Return to labs list
      } else {
        Get.snackbar(
          'error'.tr,
          labsProvider.error ?? 'enrollment_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lab = Get.arguments as LabModel;
    final labsProvider = context.watch<LabsProvider>();
    final isEnrolled = labsProvider.labs.any((l) => l.id == lab.id);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'lab_details'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                lab.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${'teacher'.tr}: ${lab.teacherName}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (lab.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  'description'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(lab.description!),
              ],
              const Spacer(),
              if (!isEnrolled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: labsProvider.isEnrolling
                        ? null
                        : () => _handleEnroll(context, lab.id),
                    icon: labsProvider.isEnrolling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(labsProvider.isEnrolling
                        ? 'enrolling'.tr
                        : 'enroll'.tr),
                  ),
                ),
              if (!isEnrolled) const SizedBox(height: 12),
              if (isEnrolled) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.sessions,
                        arguments: lab.id,
                      );
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text('view_sessions'.tr),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.chat,
                        arguments: lab.id,
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text('chat'.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


