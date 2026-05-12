import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/session_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_text_field.dart';

class SessionFormScreen extends StatefulWidget {
  final String thesisId;
  final String thesisTitle;
  const SessionFormScreen({
    super.key,
    required this.thesisId,
    this.thesisTitle = '',
  });
  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  int _durationMin = 60;
  double? _lat;
  double? _lng;
  String? _locationLabel;
  bool _fetchingLocation = false;
  bool _loading = false;
  final List<String> _actionItems = [];
  @override
  void dispose() {
    _summaryCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLabel =
            LocationService.formatCoords(pos.latitude, pos.longitude);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not get location. Check permissions.')),
      );
    }
    if (mounted) setState(() => _fetchingLocation = false);
  }

  void _addActionItem() {
    final text = _actionCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _actionItems.add(text);
      _actionCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final session = SessionModel(
        id: const Uuid().v4(),
        thesisId: widget.thesisId,
        scheduledAt: _scheduledAt,
        durationMin: _durationMin,
        latitude: _lat,
        longitude: _lng,
        locationLabel: _locationLabel,
        status: 'scheduled',
        summary: _summaryCtrl.text.trim(),
        actionItems: List.from(_actionItems),
      );
      final created = await FirestoreService().createSession(session);
      await NotificationService.scheduleSessionReminder(
        id: created.id.hashCode,
        thesisTitle: widget.thesisTitle.isEmpty ? 'Thesis' : widget.thesisTitle,
        sessionTime: created.scheduledAt,
      );
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
        title: const Text('Schedule Session'),
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
              _sectionLabel('Date & Time'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEE, d MMM yyyy · HH:mm')
                            .format(_scheduledAt),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Duration'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [30, 60, 90, 120].map((min) {
                  final selected = _durationMin == min;
                  return GestureDetector(
                    onTap: () => setState(() => _durationMin = min),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${min}m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Meeting Location (GPS)'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lat != null
                          ? Icons.location_on_rounded
                          : Icons.location_off_outlined,
                      color: _lat != null
                          ? AppColors.success
                          : AppColors.textLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationLabel ?? 'No location captured yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: _lat != null
                              ? AppColors.textPrimary
                              : AppColors.textLight,
                        ),
                      ),
                    ),
                    if (_fetchingLocation)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      TextButton(
                        onPressed: _fetchLocation,
                        child: Text(
                          _lat != null ? 'Update' : 'Capture',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Session Summary (optional)',
                hint: 'Key discussion points…',
                controller: _summaryCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _sectionLabel('Action Items'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _actionCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add an action item…',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        hintStyle: const TextStyle(color: AppColors.textLight),
                      ),
                      onSubmitted: (_) => _addActionItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addActionItem,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_actionItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._actionItems.asMap().entries.map((e) => _ActionChip(
                      label: e.value,
                      onRemove: () =>
                          setState(() => _actionItems.removeAt(e.key)),
                    )),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Schedule Session',
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActionChip({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
