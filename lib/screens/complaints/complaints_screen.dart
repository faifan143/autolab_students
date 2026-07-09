import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../models/lab_model.dart';
import '../../providers/complaints_provider.dart';
import '../../providers/labs_provider.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isAnonymous = false;
  String? _selectedLabId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintsProvider>().loadMyComplaints();
      final labs = context.read<LabsProvider>();
      if (labs.enrolledLabs.isEmpty && !labs.isLoading) {
        labs.loadLabs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('complaints'.tr),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'submit_complaint'.tr),
            Tab(text: 'my_complaints'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitTab(context),
          _buildHistoryTab(context),
        ],
      ),
    );
  }

  Widget _buildSubmitTab(BuildContext context) {
    final complaintsProvider = context.watch<ComplaintsProvider>();
    final labsProvider = context.watch<LabsProvider>();
    final labs = labsProvider.enrolledLabs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'complaint_description'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedLabId,
              decoration: InputDecoration(
                labelText: 'related_lab'.tr,
                hintText: 'optional'.tr,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('general_complaint'.tr),
                ),
                ...labs.map(
                  (lab) => DropdownMenuItem<String?>(
                    value: lab.id,
                    child: Text(lab.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedLabId = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              minLines: 5,
              maxLines: 10,
              maxLength: 4000,
              decoration: InputDecoration(
                labelText: 'complaint_content'.tr,
                hintText: 'complaint_content_hint'.tr,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'complaint_required'.tr;
                if (text.length < 10) return 'complaint_too_short'.tr;
                return null;
              },
            ),
            CheckboxListTile(
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v ?? false),
              contentPadding: EdgeInsets.zero,
              title: Text('submit_anonymously'.tr),
            ),
            if (complaintsProvider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                complaintsProvider.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: complaintsProvider.isSubmitting ? null : _submit,
              icon: complaintsProvider.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text('submit_complaint'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final provider = context.watch<ComplaintsProvider>();
    if (provider.isLoading && provider.complaints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.complaints.isEmpty) {
      return Center(
        child: Text(
          provider.error ?? 'no_complaints_yet'.tr,
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadMyComplaints,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: provider.complaints.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final complaint = provider.complaints[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusChip(status: complaint.status),
                      const Spacer(),
                      Text(
                        complaint.createdAt != null
                            ? _formatDate(complaint.createdAt!)
                            : '-',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(complaint.content),
                  if (complaint.adminNote != null &&
                      complaint.adminNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${'admin_note'.tr}: ${complaint.adminNote}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final labsProvider = context.read<LabsProvider>();
    String? teacherId;
    if (_selectedLabId != null) {
      LabModel? selectedLab;
      for (final lab in labsProvider.enrolledLabs) {
        if (lab.id == _selectedLabId) {
          selectedLab = lab;
          break;
        }
      }
      teacherId = selectedLab?.teacherId;
    }

    final success = await context.read<ComplaintsProvider>().submitComplaint(
          content: _contentController.text,
          isAnonymous: _isAnonymous,
          labId: _selectedLabId,
          teacherId: teacherId,
        );

    if (!mounted) return;
    if (success) {
      _contentController.clear();
      setState(() {
        _isAnonymous = false;
      });
      Get.snackbar(
        'success'.tr,
        'complaint_submitted'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      _tabController.animateTo(1);
    }
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _mapStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  (String, Color) _mapStatus(String raw) {
    switch (raw) {
      case 'resolved':
        return ('resolved'.tr, Colors.green);
      case 'dismissed':
        return ('dismissed'.tr, Colors.grey);
      case 'in_review':
        return ('in_review'.tr, Colors.orange);
      case 'new':
      default:
        return ('new'.tr, Colors.blue);
    }
  }
}
