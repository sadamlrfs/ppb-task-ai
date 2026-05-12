import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/thesis_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_text_field.dart';

class ThesisFormScreen extends StatefulWidget {
  final ThesisModel? existing;
  final bool isSetup;
  const ThesisFormScreen({super.key, this.existing, this.isSetup = false});
  @override
  State<ThesisFormScreen> createState() => _ThesisFormScreenState();
}

class _ThesisFormScreenState extends State<ThesisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));
  String _status = 'planning';
  bool _loading = false;
  bool get _isEdit => widget.existing != null;
  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _abstractCtrl.text = t.abstract;
      _fieldCtrl.text = t.field;
      _supervisorCtrl.text = t.supervisorId;
      _targetDate = t.targetDate;
      _status = t.status;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _fieldCtrl.dispose();
    _supervisorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final uid = context.read<AuthProvider>().user!.uid;
    final fs = FirestoreService();
    try {
      if (_isEdit) {
        await fs.updateThesis(widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          abstract: _abstractCtrl.text.trim(),
          field: _fieldCtrl.text.trim(),
          supervisorId: _supervisorCtrl.text.trim(),
          targetDate: _targetDate,
          status: _status,
        ));
      } else {
        final thesis = ThesisModel(
          id: const Uuid().v4(),
          title: _titleCtrl.text.trim(),
          abstract: _abstractCtrl.text.trim(),
          field: _fieldCtrl.text.trim(),
          studentId: uid,
          supervisorId: _supervisorCtrl.text.trim(),
          status: _status,
          startDate: DateTime.now(),
          targetDate: _targetDate,
        );
        await fs.createThesis(thesis);
      }
      if (mounted && !widget.isSetup) Navigator.pop(context);
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Thesis'),
        content: const Text(
            'This will permanently delete the thesis and cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    await FirestoreService().deleteThesis(widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isSetup
            ? 'Setup Your Thesis'
            : _isEdit
                ? 'Edit Thesis'
                : 'New Thesis'),
        automaticallyImplyLeading: !widget.isSetup,
        leading: widget.isSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (_isEdit && !widget.isSetup)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: _delete,
            ),
        ],
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
                label: 'Thesis Title',
                hint: 'e.g. AI-based Water Quality Detection',
                controller: _titleCtrl,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Research Field',
                hint: 'e.g. Machine Learning, IoT',
                controller: _fieldCtrl,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Field is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Abstract',
                hint: 'Brief description of your thesis…',
                controller: _abstractCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Supervisor Name / Email',
                hint: 'e.g. Dr. Siti Rahma',
                controller: _supervisorCtrl,
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Target Completion',
                value: _targetDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              _StatusSelector(
                value: _status,
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Save Changes' : 'Create Thesis',
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
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DateField(
      {required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  DateFormat('d MMMM yyyy').format(value),
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StatusSelector({required this.value, required this.onChanged});
  static const _statuses = [
    ('planning', 'Planning'),
    ('in_progress', 'In Progress'),
    ('review', 'Under Review'),
    ('completed', 'Completed'),
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statuses.map((s) {
            final selected = value == s.$1;
            return GestureDetector(
              onTap: () => onChanged(s.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? AppColors.surface : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
