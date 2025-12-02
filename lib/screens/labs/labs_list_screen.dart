import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/labs_provider.dart';
import '../../routes/app_routes.dart';

class LabsListScreen extends StatelessWidget {
  const LabsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labsProvider = context.watch<LabsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'my_labs'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: labsProvider.isLoading && labsProvider.labs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : labsProvider.labs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('no_data'.tr),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => labsProvider.loadLabs(),
                                child: Text('retry'.tr),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => labsProvider.loadLabs(),
                          child: ListView.builder(
                            itemCount: labsProvider.labs.length,
                            itemBuilder: (context, index) {
                              final lab = labsProvider.labs[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(lab.name),
                                  subtitle: Text('${'teacher'.tr}: ${lab.teacherName}'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    Get.toNamed(
                                      AppRoutes.labDetail,
                                      arguments: lab,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


