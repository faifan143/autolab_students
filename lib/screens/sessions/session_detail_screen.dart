import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sessions_provider.dart';
import '../../routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _hasInitialized = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = Get.arguments as String?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted && _sessionId != null) {
        _hasInitialized = true;
        final sessionsProvider = Provider.of<SessionsProvider>(
          context,
          listen: false,
        );
        sessionsProvider.loadSession(_sessionId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = Provider.of<SessionsProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: _buildBackButton(context),
              title: const SizedBox.shrink(),
            ),
            // Content
            if (sessionsProvider.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading session...',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else if (sessionsProvider.currentSession == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[600],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Session Not Found',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sessionId != null
                            ? () => sessionsProvider.loadSession(_sessionId!)
                            : null,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Session Info Cards
                      _buildInfoCard(
                        context,
                        icon: Icons.event_outlined,
                        label: 'Start Time',
                        value: DateFormat(
                          'MMM dd, yyyy HH:mm',
                        ).format(sessionsProvider.currentSession!.startTime),
                      ),
                      const SizedBox(height: 10),
                      if (sessionsProvider.currentSession!.endTime != null)
                        _buildInfoCard(
                          context,
                          icon: Icons.event_available_outlined,
                          label: 'End Time',
                          value: DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(sessionsProvider.currentSession!.endTime!),
                        ),
                      const SizedBox(height: 10),
                      _buildStatusCard(
                        context,
                        isStreaming:
                            sessionsProvider.currentSession!.isStreaming,
                      ),
                      const SizedBox(height: 20),
                      // Recorded Video Section
                      if (sessionsProvider.currentSession!.recordedVideoUrl !=
                          null) ...[
                        Text(
                          'Recording',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildVideoButton(
                          context,
                          onTap: () async {
                            final url = Uri.parse(
                              sessionsProvider
                                  .currentSession!
                                  .recordedVideoUrl!,
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          label: 'Watch Recording',
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Live Stream Button
                      if (sessionsProvider.currentSession!.isStreaming) ...[
                        Text(
                          'Live Session',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _sessionId != null
                                ? () {
                                    Get.toNamed(
                                      AppRoutes.sessionStreaming,
                                      arguments: _sessionId,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.live_tv, size: 18),
                            label: const Text(
                              'Join Live Stream',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, {required bool isStreaming}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isStreaming
            ? Colors.red[50]
            : Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border.all(
          color: isStreaming
              ? Colors.red[200]!
              : Theme.of(context).primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (isStreaming)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red[100],
              ),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red[600],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.videocam_outlined,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isStreaming ? 'Live Now' : 'Recording Available',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isStreaming ? Colors.red[600] : null,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoButton(
    BuildContext context, {
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).primaryColor.withOpacity(0.08),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.15),
              ),
              child: Icon(
                Icons.play_circle_outlined,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recorded Video',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
