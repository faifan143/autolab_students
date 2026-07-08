import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../routes/app_routes.dart';
import '../../providers/attendance_provider.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      attendanceProvider.loadAttendance();
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'attendance'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'attendance_qr_hint'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: attendanceProvider.isLoading &&
                      attendanceProvider.attendanceHistory.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceProvider.attendanceHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('no_data'.tr),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    attendanceProvider.loadAttendance(),
                                child: Text('retry'.tr),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => attendanceProvider.loadAttendance(),
                          child: ListView.builder(
                            itemCount:
                                attendanceProvider.attendanceHistory.length,
                            itemBuilder: (context, index) {
                              final attendance =
                                  attendanceProvider.attendanceHistory[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    DateFormat('MMM dd, yyyy HH:mm')
                                        .format(attendance.timestamp),
                                  ),
                                  subtitle:
                                      Text(_getStatusText(attendance.status)),
                                  trailing: _getStatusIcon(attendance.status),
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'present'.tr;
      case 'late':
        return 'late'.tr;
      case 'absent':
        return 'absent'.tr;
      default:
        return status;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'late':
        return const Icon(Icons.schedule, color: Colors.orange);
      case 'absent':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help);
    }
  }
}


