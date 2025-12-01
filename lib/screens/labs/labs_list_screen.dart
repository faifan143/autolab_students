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
    
    if (labsProvider.isLoading && labsProvider.labs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('my_labs'.tr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('my_labs'.tr),
      ),
      body: labsProvider.labs.isEmpty
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
    );
  }
}


