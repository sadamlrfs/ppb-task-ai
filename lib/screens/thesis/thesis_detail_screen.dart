import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/thesis_model.dart';
import '../../models/milestone_model.dart';
import '../../models/session_model.dart';
import '../../models/attachment_model.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/section_header.dart';
import '../milestones/milestone_form_screen.dart';
import '../sessions/session_form_screen.dart';
import '../notes/note_form_screen.dart';
import '../attachments/attachment_form_screen.dart';
import '../media/media_gallery_screen.dart';
import 'thesis_form_screen.dart';

class ThesisDetailScreen extends StatelessWidget {
  final ThesisModel thesis;
  final bool isRoot;
  const ThesisDetailScreen(
      {super.key, required this.thesis, this.isRoot = false});
  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isRoot ? 'My Thesis' : 'Thesis Detail'),
        automaticallyImplyLeading: !isRoot,
        leading: isRoot
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => _showProfileSheet(context, auth),
                  child: CircleAvatar(
                    backgroundColor: AppColors.lavender,
                    child: Text(
                      (auth.user?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ThesisFormScreen(existing: thesis))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        children: [
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.lavender, AppColors.cardLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: thesis.status),
                const SizedBox(height: 12),
                Text(
                  thesis.title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                if (thesis.field.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(thesis.field,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Due ${DateFormat('d MMM yyyy').format(thesis.targetDate)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (thesis.supervisorId.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          thesis.supervisorId,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (thesis.abstract.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    thesis.abstract,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Milestones',
            actionLabel: '+ Add',
            onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MilestoneFormScreen(thesisId: thesis.id))),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<MilestoneModel>>(
            stream: fs.milestonesStream(thesis.id),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: AppColors.error)),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return _EmptySection(
                  label: 'No milestones yet',
                  onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MilestoneFormScreen(thesisId: thesis.id))),
                );
              }
              return Column(
                children: items
                    .map((m) => _MilestoneRow(
                          milestone: m,
                          onComplete: () => fs.completeMilestone(m.id),
                          onDelete: () => fs.deleteMilestone(m.id),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Sessions',
            actionLabel: '+ Add',
            onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SessionFormScreen(thesisId: thesis.id))),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SessionModel>>(
            stream: fs.sessionsStream(thesis.id),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: AppColors.error)),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return _EmptySection(
                  label: 'No sessions yet',
                  onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              SessionFormScreen(thesisId: thesis.id))),
                );
              }
              return Column(
                children: items.map((s) => _SessionRow(session: s)).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Notes',
            actionLabel: '+ Add',
            onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NoteFormScreen(thesisId: thesis.id))),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<NoteModel>>(
            stream: fs.notesStream(thesis.id),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: AppColors.error)),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return _EmptySection(
                  label: 'No notes yet',
                  onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NoteFormScreen(thesisId: thesis.id))),
                );
              }
              return Column(
                children: items
                    .map((n) =>
                        _NoteRow(note: n, onDelete: () => fs.deleteNote(n.id)))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Attachments',
            actionLabel: '+ Add',
            onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AttachmentFormScreen(thesisId: thesis.id))),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AttachmentModel>>(
            stream: fs.attachmentsStream(thesis.id),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Error: ${snap.error}',
                      style: const TextStyle(color: AppColors.error)),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return _EmptySection(
                  label: 'No attachments yet',
                  onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AttachmentFormScreen(thesisId: thesis.id))),
                );
              }
              return Column(
                children: items
                    .map((a) => _AttachmentRow(
                          attachment: a,
                          onDelete: () => fs.deleteAttachment(a.id),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _QuickLink(
                  icon: Icons.note_alt_outlined,
                  label: 'Add Note',
                  color: AppColors.lavender,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NoteFormScreen(thesisId: thesis.id))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickLink(
                  icon: Icons.perm_media_rounded,
                  label: 'Media',
                  color: AppColors.cardLight,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MediaGalleryScreen(
                              thesisId: thesis.id, thesisTitle: thesis.title))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.lavender,
              child: Text(
                (auth.user?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              auth.user?.name ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              auth.user?.email ?? '',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  Color get _color {
    switch (status) {
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

  String get _label {
    switch (status) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final MilestoneModel milestone;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  const _MilestoneRow(
      {required this.milestone,
      required this.onComplete,
      required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final done = milestone.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: done ? null : onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                border: done
                    ? null
                    : Border.all(color: AppColors.textLight, width: 2),
                borderRadius: BorderRadius.circular(7),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      milestone.isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.calendar_today_outlined,
                      size: 11,
                      color: milestone.isOverdue
                          ? AppColors.error
                          : AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM yyyy').format(milestone.dueDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: milestone.isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textLight, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final SessionModel session;
  const _SessionRow({required this.session});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, d MMM y · HH:mm')
                      .format(session.scheduledAt),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (session.hasLocation)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.locationDisplay,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _SessionStatusChip(status: session.status),
        ],
      ),
    );
  }
}

class _SessionStatusChip extends StatelessWidget {
  final String status;
  const _SessionStatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'done':
        color = AppColors.success;
        label = 'Done';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.primary;
        label = 'Upcoming';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;
  const _EmptySection({required this.label, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.textLight.withValues(alpha: 0.4),
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onDelete;
  const _NoteRow({required this.note, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.note_alt_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.body,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy, HH:mm').format(note.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textLight, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback onDelete;
  const _AttachmentRow({required this.attachment, required this.onDelete});
  static IconData _iconFor(String kind) {
    switch (kind) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'image':
        return Icons.image_outlined;
      case 'audio':
        return Icons.headphones_outlined;
      case 'doc':
        return Icons.description_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(attachment.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(attachment.kind),
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attachment.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(attachment.sourceHost,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textLight, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
