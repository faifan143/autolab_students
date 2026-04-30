import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/sessions_provider.dart';
import '../../models/lab_model.dart';
import '../../routes/app_routes.dart';

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
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted && _labId != null) {
        _hasInitialized = true;
        final sessionsProvider = Provider.of<SessionsProvider>(
          context,
          listen: false,
        );
        sessionsProvider.loadLabSessions(_labId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = Provider.of<SessionsProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context, sessionsProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sessions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Lab sessions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SessionsProvider sessionsProvider,
  ) {
    if (sessionsProvider.isLoading && sessionsProvider.sessions.isEmpty) {
      return Center(
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
              'Loading sessions...',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey[500]),
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
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No Sessions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'No sessions available yet',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _labId != null
          ? () => sessionsProvider.loadLabSessions(_labId!)
          : () async {},
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: sessionsProvider.sessions.length,
        itemBuilder: (context, index) {
          final session = sessionsProvider.sessions[index];
          return _buildSessionCard(context, session);
        },
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, dynamic session) {
    final isStreaming = session.isStreaming ?? false;
    final dateTime = session.startTime;
    final date = DateFormat('MMM dd').format(dateTime);
    final time = DateFormat('HH:mm').format(dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          Get.toNamed(AppRoutes.sessionDetail, arguments: session.id);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Date/Time Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.event_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Date/Time & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 11,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                          if (isStreaming) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Live',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.red[600],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow
                Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
