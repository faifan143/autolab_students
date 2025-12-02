import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/lab_model.dart';
import '../../routes/app_routes.dart';

class LabDetailScreen extends StatelessWidget {
  const LabDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lab = Get.arguments as LabModel;

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
            ],
          ),
        ),
      ),
    );
  }
}


