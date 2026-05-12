import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/milestone_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_text_field.dart';

class MilestoneFormScreen extends StatefulWidget {
  final String thesisId;
  final MilestoneModel? existing;
  const MilestoneFormScreen({
    super.key,
    required this.thesisId,
    this.existing,
  });
  @override
  State<MilestoneFormScreen> createState() => _MilestoneFormScreenState();
}

class _MilestoneFormScreenState extends State<MilestoneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _loading = false;
  bool get _isEdit => widget.existing != null;
  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleCtrl.text = widget.existing!.title;
      _descCtrl.text = widget.existing!.description;
      _dueDate = widget.existing!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final fs = FirestoreService();
    try {
      if (_isEdit) {
        final updated = MilestoneModel(
          id: widget.existing!.id,
          thesisId: widget.thesisId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate,
          completedAt: widget.existing!.completedAt,
          order: widget.existing!.order,
          status: widget.existing!.status,
        );
        await fs.updateMilestone(updated);
      } else {
        final milestone = MilestoneModel(
          id: const Uuid().v4(),
          thesisId: widget.thesisId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          dueDate: _dueDate,
          order: DateTime.now().millisecondsSinceEpoch,
          status: 'pending',
        );
        final created = await fs.createMilestone(milestone);
        await NotificationService.scheduleMilestoneReminder(
          id: created.id.hashCode,
          title: created.title,
          dueDate: created.dueDate,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Milestone' : 'New Milestone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Milestone Title',
                hint: 'e.g. Submit Chapter 1',
                controller: _titleCtrl,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                hint: 'Details about this milestone…',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _label('Due Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('d MMMM yyyy').format(_dueDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Save Changes' : 'Add Milestone',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
}
