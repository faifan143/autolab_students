import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../providers/labs_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_cards.dart';

class LabsListScreen extends StatefulWidget {
  const LabsListScreen({super.key});

  @override
  State<LabsListScreen> createState() => _LabsListScreenState();
}

class _LabsListScreenState extends State<LabsListScreen> {
  String _searchQuery = '';
  late final FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final labsProvider = context.read<LabsProvider>();
      if (labsProvider.enrolledLabs.isEmpty && !labsProvider.isLoading) {
        labsProvider.loadLabs();
      }
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List _filteredLabs(LabsProvider provider) {
    final allLabs = List.from(provider.enrolledLabs);
    if (_searchQuery.isEmpty) return allLabs;

    final query = _searchQuery.toLowerCase();
    return allLabs
        .where(
          (lab) =>
              lab.name.toLowerCase().contains(query) ||
              provider
                  .getTeacherName(lab.teacherId, fallback: lab.teacherName)
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final labsProvider = context.watch<LabsProvider>();
    final filteredLabs = _filteredLabs(labsProvider);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text('my_labs'.tr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              focusNode: _searchFocus,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'search_labs_hint'.tr,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _searchFocus.unfocus();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: labsProvider.isLoading && filteredLabs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredLabs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'no_labs_found'.tr,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'try_different_search'.tr
                              : 'no_labs_available'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: labsProvider.loadLabs,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLabs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lab = filteredLabs[index];
                        final teacherName = labsProvider.getTeacherName(
                          lab.teacherId,
                          fallback: lab.teacherName,
                        );

                        return AppSurfaceCard(
                          onTap: () => Get.toNamed(
                            AppRoutes.labDetail,
                            arguments: lab,
                          ),
                          child: Row(
                            children: [
                              const AppIconBadge(
                                icon: Icons.science_outlined,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lab.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${'teacher'.tr}: $teacherName',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: color.onSurfaceVariant,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
