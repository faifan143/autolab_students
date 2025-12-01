import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sessions_provider.dart';
import '../../routes/app_routes.dart';

class SessionsListScreen extends StatelessWidget {
  const SessionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labId = Get.arguments as String?;
    final sessionsProvider = Provider.of<SessionsProvider>(context);

    if (labId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sessionsProvider.loadLabSessions(labId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('sessions'.tr),
      ),
      body: sessionsProvider.isLoading && sessionsProvider.sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : sessionsProvider.sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('no_data'.tr),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => sessionsProvider.loadLabSessions(labId!),
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => sessionsProvider.loadLabSessions(labId!),
                  child: ListView.builder(
                    itemCount: sessionsProvider.sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessionsProvider.sessions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(session.startTime),
                          ),
                          subtitle: Text(
                            session.isStreaming
                                ? 'streaming'.tr
                                : 'not_streaming'.tr,
                          ),
                          trailing: session.isStreaming
                              ? const Icon(Icons.live_tv, color: Colors.red)
                              : null,
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.sessionDetail,
                              arguments: session.id,
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


