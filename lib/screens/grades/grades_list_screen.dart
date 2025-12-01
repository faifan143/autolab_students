import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/grades_provider.dart';

class GradesListScreen extends StatelessWidget {
  const GradesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gradesProvider = Provider.of<GradesProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      gradesProvider.loadGrades();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('grades'.tr),
      ),
      body: gradesProvider.isLoading && gradesProvider.grades.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : gradesProvider.grades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('no_data'.tr),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => gradesProvider.loadGrades(),
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => gradesProvider.loadGrades(),
                  child: ListView.builder(
                    itemCount: gradesProvider.grades.length,
                    itemBuilder: (context, index) {
                      final grade = gradesProvider.grades[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(grade.category),
                          subtitle: Text(
                            '${'score'.tr}: ${grade.score}/${grade.maxScore} (${grade.percentage.toStringAsFixed(1)}%)',
                          ),
                          trailing: Text(
                            '${grade.percentage.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          isThreeLine: grade.comment != null,
                          onTap: grade.comment != null
                              ? () {
                                  Get.dialog(
                                    AlertDialog(
                                      title: Text('comment'.tr),
                                      content: Text(grade.comment!),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: Text('ok'.tr),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


