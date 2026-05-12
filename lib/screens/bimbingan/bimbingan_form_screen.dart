import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bimbingan_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_text_field.dart';

class BimbinganFormScreen extends StatefulWidget {
  final String thesisId;
  final BimbinganModel? existing;
  const BimbinganFormScreen({
    super.key,
    required this.thesisId,
    this.existing,
  });
  @override
  State<BimbinganFormScreen> createState() => _BimbinganFormScreenState();
}

class _BimbinganFormScreenState extends State<BimbinganFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _loading = false;
  bool get _isEdit => widget.existing != null;
  DateTime get _combined => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _titleCtrl.text = e.title;
      _planCtrl.text = e.plan;
      _selectedDate = e.date;
      _selectedTime = TimeOfDay(hour: e.date.hour, minute: e.date.minute);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final fs = FirestoreService();
    try {
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          title: _titleCtrl.text.trim(),
          plan: _planCtrl.text.trim(),
          date: _combined,
        );
        await fs.updateBimbingan(updated);
        await NotificationService.cancelBimbinganReminders(updated.id);
        await NotificationService.scheduleBimbinganReminders(
          bimbinganId: updated.id,
          title: updated.title,
          dateTime: updated.date,
        );
      } else {
        final id = const Uuid().v4();
        final b = BimbinganModel(
          id: id,
          thesisId: widget.thesisId,
          title: _titleCtrl.text.trim(),
          plan: _planCtrl.text.trim(),
          date: _combined,
          createdAt: DateTime.now(),
        );
        await fs.createBimbingan(b);
        await NotificationService.scheduleBimbinganReminders(
          bimbinganId: id,
          title: b.title,
          dateTime: b.date,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text('Hapus Bimbingan'),
        content: const Text(
            'Yakin ingin menghapus bimbingan ini? Semua catatan, media, dan tautan terkait tidak akan terhapus otomatis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await NotificationService.cancelBimbinganReminders(widget.existing!.id);
      await FirestoreService().deleteBimbingan(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Bimbingan' : 'Bimbingan Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEdit)
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
                label: 'Judul',
                hint: 'Mis. Bimbingan ke-1',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tanggal & Waktu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('d MMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.textLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pengingat otomatis: 1 hari, 3 jam, dan 1 jam sebelum',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rencana / Agenda (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.textLight),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _planCtrl,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan rencana atau agenda bimbingan…',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppColors.textLight),
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Buat Bimbingan',
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
