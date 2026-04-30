import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/lab_model.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../providers/labs_provider.dart';
import '../../services/user_service.dart';

class LabDetailScreen extends StatefulWidget {
  const LabDetailScreen({super.key});

  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen>
    with TickerProviderStateMixin {
  UserModel? _teacher;
  bool _isLoadingTeacher = false;
  String? _teacherError;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    final args = Get.arguments;
    LabModel? lab;

    if (args is LabModel) {
      lab = args;
    } else if (args is String) {
      try {
        final labsProvider = context.read<LabsProvider>();
        lab = labsProvider.enrolledLabs.firstWhere(
          (l) => l.id == args,
          orElse: () => labsProvider.availableLabs.firstWhere(
            (l) => l.id == args,
            orElse: () => throw Exception('Lab not found'),
          ),
        );
      } catch (e) {
        return;
      }
    }

    if (lab == null || lab.teacherId == null) return;

    setState(() {
      _isLoadingTeacher = true;
      _teacherError = null;
    });

    try {
      final teacher = await UserService.getUserById(lab.teacherId!);
      if (mounted) {
        setState(() {
          _teacher = teacher;
          _isLoadingTeacher = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _teacherError = e.toString();
          _isLoadingTeacher = false;
        });
      }
    }
  }

  Future<void> _handleEnroll(BuildContext context, String labId) async {
    final labsProvider = context.read<LabsProvider>();
    final success = await labsProvider.enrollInLab(labId);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(context, 'Enrolled! 🎉', isSuccess: true),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.back();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            context,
            labsProvider.error ?? 'Failed to enroll',
            isSuccess: false,
          ),
        );
      }
    }
  }

  SnackBar _buildSnackBar(
    BuildContext context,
    String message, {
    required bool isSuccess,
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
      duration: const Duration(milliseconds: 1800),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    LabModel? lab;

    if (args is LabModel) {
      lab = args;
    } else if (args is String) {
      final labsProvider = context.watch<LabsProvider>();
      try {
        lab = labsProvider.enrolledLabs.firstWhere(
          (l) => l.id == args,
          orElse: () => labsProvider.availableLabs.firstWhere(
            (l) => l.id == args,
            orElse: () => throw Exception('Lab not found'),
          ),
        );
      } catch (e) {
        lab = null;
      }
    }

    if (lab == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[600]),
                const SizedBox(height: 12),
                Text(
                  'Lab Not Found',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final labModel = lab;
    final labsProvider = context.watch<LabsProvider>();
    final isEnrolled = labsProvider.labs.any((l) => l.id == labModel.id);

    return Scaffold(
      floatingActionButton: isEnrolled
          ? FloatingActionButton(
              onPressed: () => Get.toNamed(AppRoutes.qrScanner),
              child: const Icon(Icons.qr_code_scanner),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              toolbarHeight: 56,
              leading: _buildBackButton(context),
              title: const SizedBox.shrink(),
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      labModel.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Teacher
                    _buildTeacherSection(context),
                    const SizedBox(height: 20),

                    // Description
                    if (labModel.description != null &&
                        labModel.description!.isNotEmpty)
                      _buildDescription(context, labModel.description!),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: !isEnrolled
                    ? _buildEnrollButton(context, labModel, labsProvider)
                    : _buildActionGrid(context, labModel),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  Widget _buildTeacherSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructor',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingTeacher)
            _buildLoadingState(context)
          else if (_teacherError != null)
            _buildErrorState(context)
          else if (_teacher != null)
            _buildTeacherInfo(context)
          else
            _buildFallbackTeacher(context),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading...',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
        const SizedBox(width: 8),
        Text(
          'Failed to load',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.red[600]),
        ),
      ],
    );
  }

  Widget _buildTeacherInfo(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(_fadeController),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.25),
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                _teacher!.name.isNotEmpty
                    ? _teacher!.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teacher!.name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.mail_outline, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _teacher!.email,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTeacher(BuildContext context) {
    return Text(
      Get.arguments is LabModel
          ? (Get.arguments as LabModel).teacherName
          : 'Unknown',
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDescription(BuildContext context, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).primaryColor.withOpacity(0.03),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
            ),
          ),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollButton(
    BuildContext context,
    LabModel lab,
    LabsProvider labsProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: labsProvider.isEnrolling
            ? null
            : () => _handleEnroll(context, lab.id),
        icon: labsProvider.isEnrolling
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : const Icon(Icons.check_circle_outline, size: 18),
        label: Text(
          labsProvider.isEnrolling ? 'Enrolling...' : 'Enroll Now',
          style: const TextStyle(
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
    );
  }

  Widget _buildActionGrid(BuildContext context, LabModel lab) {
    final actions = [
      (
        icon: Icons.event_outlined,
        label: 'Sessions',
        route: AppRoutes.sessions,
        args: lab.id,
      ),
      (
        icon: Icons.bar_chart_outlined,
        label: 'Grades',
        route: AppRoutes.grades,
        args: lab.id,
      ),
      (
        icon: Icons.folder_open_outlined,
        label: 'Files',
        route: AppRoutes.files,
        args: lab.id,
      ),
      (
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
        route: AppRoutes.chat,
        args: {
          'channel': 'lab:${lab.id}',
          'labId': lab.id,
          'labName': lab.name,
        },
      ),
    ];

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(
              context,
              action.icon,
              action.label,
              () => Get.toNamed(action.route, arguments: action.args),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
