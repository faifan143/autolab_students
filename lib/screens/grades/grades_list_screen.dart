import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../providers/grades_provider.dart';
import '../../models/lab_model.dart';
import '../../widgets/app_cards.dart';

class GradesListScreen extends StatefulWidget {
  const GradesListScreen({super.key});

  @override
  State<GradesListScreen> createState() => _GradesListScreenState();
}

class _GradesListScreenState extends State<GradesListScreen> {
  bool _hasInitialized = false;
  String? _labId;
  String? _selectedCategory;

  static const List<String> _categories = [
    'Quiz',
    'Exam',
    'Project',
    'Presentation',
    'Assignment',
  ];

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
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        final gradesProvider = Provider.of<GradesProvider>(
          context,
          listen: false,
        );
        gradesProvider.loadGrades(labId: _labId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradesProvider = Provider.of<GradesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('grades'.tr),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(context),
            Expanded(child: _buildContent(context, gradesProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              context,
              label: 'all'.tr,
              isSelected: _selectedCategory == null,
              onTap: () => setState(() => _selectedCategory = null),
            ),
            const SizedBox(width: 6),
            ..._categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildChip(
                  context,
                  label: category,
                  isSelected: _selectedCategory == category,
                  onTap: () => setState(() => _selectedCategory = category),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GradesProvider gradesProvider) {
    if (gradesProvider.error != null && gradesProvider.grades.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => gradesProvider.loadGrades(labId: _labId),
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  'Failed to load grades',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    gradesProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (gradesProvider.isLoading && gradesProvider.grades.isEmpty) {
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
              'loading_grades'.tr,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (gradesProvider.grades.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => gradesProvider.loadGrades(labId: _labId),
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assessment_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  'no_grades_yet'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'grades_will_appear'.tr,
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

    final filteredGrades = _selectedCategory == null
        ? gradesProvider.grades
        : gradesProvider.grades
              .where((grade) => grade.category == _selectedCategory)
              .toList();

    if (filteredGrades.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => gradesProvider.loadGrades(labId: _labId),
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  'no_grades_found'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCategory != null
                      ? 'no_grades_for_category'.tr
                      : 'grades_will_appear'.tr,
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
      onRefresh: () => gradesProvider.loadGrades(labId: _labId),
      color: Theme.of(context).primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGrades.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final grade = filteredGrades[index];
          return _buildGradeCard(context, grade);
        },
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, dynamic grade) {
    final percentage = grade.percentage ?? 0.0;
    final color = _getGradeColor(percentage);

    return AppSurfaceCard(
        onTap: grade.comment != null
            ? () => _showCommentDialog(context, grade.comment!)
            : null,
        padding: const EdgeInsets.all(12),
        child: Row(
              children: [
                // Score Circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Category & Score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.category,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outlined,
                            size: 11,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              grade.maxScore != null
                                  ? '${grade.score.toStringAsFixed(0)}/${grade.maxScore!.toStringAsFixed(0)}'
                                  : '${grade.score.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Progress Bar
                if (grade.maxScore != null)
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.grey[300],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                // Comment Indicator
                if (grade.comment != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green[600]!;
    if (percentage >= 80) return Colors.blue[600]!;
    if (percentage >= 70) return Colors.amber[600]!;
    if (percentage >= 60) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  void _showCommentDialog(BuildContext context, String comment) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'comment'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                comment,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text('close'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
