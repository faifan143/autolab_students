import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/labs_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fabController;
  bool _showFab = false;
  String _searchQuery = '';
  late FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchFocus = FocusNode();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final labsProvider = Provider.of<LabsProvider>(context, listen: false);

        // Load user if not already loaded
        if (authProvider.isAuthenticated && authProvider.currentUser == null) {
          authProvider.loadCurrentUser();
        }

        // Load labs if needed
        if (labsProvider.enrolledLabs.isEmpty && !labsProvider.isLoading) {
          labsProvider.loadLabs();
        }
      }
    });
  }

  void _onScroll() {
    // Show FAB when scrolling down
    if (_scrollController.offset > 300) {
      if (!_showFab) {
        setState(() => _showFab = true);
        _fabController.forward();
      }
    } else {
      if (_showFab) {
        setState(() => _showFab = false);
        _fabController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List _getFilteredLabs(LabsProvider provider) {
    // Backend only returns enrolled labs for students.
    final allLabs = List.from(provider.enrolledLabs);

    if (_searchQuery.isEmpty) return allLabs;

    return allLabs
        .where(
          (lab) =>
              lab.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              provider
                  .getTeacherName(lab.teacherId, fallback: lab.teacherName)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labsProvider = context.watch<LabsProvider>();
    final filteredLabs = _getFilteredLabs(labsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with avatar and settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _HomeTopBar(theme: theme),
            ),
            // Search Bar
            _buildSearchBar(context),
            // Labs Content
            Expanded(child: _buildContent(context, labsProvider, filteredLabs)),
          ],
        ),
      ),
      floatingActionButton: _buildScrollToTopFab(),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        focusNode: _searchFocus,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search labs or teachers...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    setState(() => _searchQuery = '');
                    _searchFocus.unfocus();
                  },
                  child: Icon(Icons.close, color: Colors.grey[400], size: 18),
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).primaryColor.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LabsProvider labsProvider,
    List filteredLabs,
  ) {
    if (labsProvider.isLoading && filteredLabs.isEmpty) {
      return _buildLoadingState(context);
    }

    if (filteredLabs.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () => labsProvider.loadLabs(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filteredLabs.length,
        itemBuilder: (context, index) {
          final lab = filteredLabs[index];

          return _buildLabCard(
            context,
            lab,
            labsProvider: labsProvider,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildLabCard(
    BuildContext context,
    dynamic lab, {
    required LabsProvider labsProvider,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.labDetail, arguments: lab),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Minimal icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.2),
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Lab info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lab.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        labsProvider.getTeacherName(
                          lab.teacherId,
                          fallback: lab.teacherName,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[500],
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToTopFab() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(_fabController),
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        },
        elevation: 2,
        child: const Icon(Icons.arrow_upward, size: 18),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
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
            'Loading labs...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey[500],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No labs found',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search'
                : 'No labs available yet',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[500],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name ?? 'student'.tr;

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('greeting_generic'.tr, style: theme.textTheme.bodySmall),
              Text(name, style: theme.textTheme.titleMedium),
            ],
          ),
        ),

        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.complaints),
          icon: const Icon(Icons.report_gmailerrorred_outlined),
          tooltip: 'complaints'.tr,
        ),
        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}
