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
      appBar: AppBar(
        title: Text('lab_details'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                icon: const Icon(Icons.event),
                label: Text('view_sessions'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


