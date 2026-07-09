import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/lab_model.dart';
import '../../providers/sessions_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_cards.dart';

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  bool _hasInitialized = false;
  String? _labId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is String) {
      _labId = args;
    } else if (args is LabModel) {
      _labId = args.id;
    } else if (args is Map<String, dynamic>) {
      _labId = args['labId'] as String?;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted && _labId != null) {
        _hasInitialized = true;
        context.read<SessionsProvider>().loadLabSessions(_labId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = context.watch<SessionsProvider>();
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('sessions'.tr),
      ),
      body: _buildContent(context, sessionsProvider, theme, color),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SessionsProvider sessionsProvider,
    ThemeData theme,
    ColorScheme color,
  ) {
    if (sessionsProvider.isLoading && sessionsProvider.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'loading_sessions'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (sessionsProvider.sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _labId != null
            ? () => sessionsProvider.loadLabSessions(_labId!)
            : () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 48,
                      color: color.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'no_sessions'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'no_sessions_available'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _labId != null
          ? () => sessionsProvider.loadLabSessions(_labId!)
          : () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sessionsProvider.sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = sessionsProvider.sessions[index];
          return _SessionCard(session: session);
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final dynamic session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isStreaming = session.isStreaming ?? false;
    final dateTime = session.startTime as DateTime;
    final date = DateFormat('MMM dd, yyyy').format(dateTime);
    final time = DateFormat('HH:mm').format(dateTime);

    return AppSurfaceCard(
      onTap: () => Get.toNamed(AppRoutes.sessionDetail, arguments: session.id),
      child: Row(
        children: [
          const AppIconBadge(icon: Icons.event_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 14,
                      color: color.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    if (isStreaming) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'live'.tr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color.onSurfaceVariant),
        ],
      ),
    );
  }
}
