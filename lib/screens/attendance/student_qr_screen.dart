import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/attendance_provider.dart';

class StudentQrScreen extends StatefulWidget {
  const StudentQrScreen({super.key});

  @override
  State<StudentQrScreen> createState() => _StudentQrScreenState();
}

class _StudentQrScreenState extends State<StudentQrScreen> {
  Timer? _refreshTimer;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = Get.arguments as String?;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQr());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQr() async {
    if (_sessionId == null || !mounted) return;

    final provider = context.read<AttendanceProvider>();
    final success = await provider.loadCheckInQr(_sessionId!);

    if (!mounted) return;

    if (!success) {
      Get.snackbar(
        'error'.tr,
        provider.error ?? 'attendance_qr_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 25), _refreshQr);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final token = provider.checkInToken;

    return Scaffold(
      appBar: AppBar(
        title: Text('show_attendance_qr'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'show_attendance_qr_hint'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: provider.isLoading && token == null
                    ? const CircularProgressIndicator()
                    : token == null
                        ? Text(provider.error ?? 'attendance_qr_error'.tr)
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: token,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                            ),
                          ),
              ),
            ),
            if (provider.checkInExpiresAt != null)
              Text(
                '${'expires_at'.tr} ${provider.checkInExpiresAt!.toLocal().toString().substring(11, 19)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isLoading ? null : _refreshQr,
                icon: const Icon(Icons.refresh),
                label: Text('refresh_qr'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
