import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sessions_provider.dart';
import '../../routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionId = Get.arguments as String;
    final sessionsProvider = Provider.of<SessionsProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sessionsProvider.loadSession(sessionId);
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: sessionsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : sessionsProvider.currentSession == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Get.back(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'session_details'.tr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text('no_data'.tr),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => sessionsProvider.loadSession(sessionId),
                          child: Text('retry'.tr),
                        ),
                      ],
                    )
                  : Column(
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
                              'session_details'.tr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'start_time'.tr,
                          value: DateFormat('MMM dd, yyyy HH:mm').format(
                            sessionsProvider.currentSession!.startTime,
                          ),
                        ),
                        if (sessionsProvider.currentSession!.endTime != null)
                          _InfoRow(
                            label: 'end_time'.tr,
                            value: DateFormat('MMM dd, yyyy HH:mm').format(
                              sessionsProvider.currentSession!.endTime!,
                            ),
                          ),
                        _InfoRow(
                          label: 'streaming'.tr,
                          value: sessionsProvider.currentSession!.isStreaming
                              ? 'streaming'.tr
                              : 'not_streaming'.tr,
                        ),
                        if (sessionsProvider.currentSession!.recordedVideoUrl !=
                            null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'recorded_video'.tr,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(
                                sessionsProvider.currentSession!.recordedVideoUrl!,
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            icon: const Icon(Icons.play_circle),
                            label: Text('watch_live_stream'.tr),
                          ),
                        ],
                        const Spacer(),
                        if (sessionsProvider.currentSession!.isStreaming)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Get.toNamed(
                                  AppRoutes.sessionStreaming,
                                  arguments: sessionId,
                                );
                              },
                              icon: const Icon(Icons.live_tv),
                              label: Text('watch_live_stream'.tr),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}


