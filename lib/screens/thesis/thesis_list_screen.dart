import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/thesis_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/section_header.dart';
import 'thesis_form_screen.dart';
import 'thesis_detail_screen.dart';

class ThesisListScreen extends StatelessWidget {
  const ThesisListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Theses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ThesisFormScreen())),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Thesis',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<ThesisModel>>(
        stream: fs.thesesStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return _EmptyThesis(
              onAdd: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ThesisFormScreen())),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ThesisCard(
              thesis: list[i],
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ThesisDetailScreen(thesis: list[i]))),
            ),
          );
        },
      ),
    );
  }
}

class _ThesisCard extends StatelessWidget {
  final ThesisModel thesis;
  final VoidCallback onTap;
  const _ThesisCard({required this.thesis, required this.onTap});
  Color get _statusColor {
    switch (thesis.status) {
      case 'completed':
        return AppColors.success;
      case 'review':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.textLight;
    }
  }

  String get _statusLabel {
    switch (thesis.status) {
      case 'in_progress':
        return 'In Progress';
      case 'review':
        return 'Under Review';
      case 'completed':
        return 'Completed';
      default:
        return 'Planning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              thesis.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              thesis.field,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Due ${DateFormat('d MMM yyyy').format(thesis.targetDate)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyThesis extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyThesis({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.menu_book_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No theses yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Create your first thesis to get started',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Thesis'),
          ),
        ],
      ),
    );
  }
}
