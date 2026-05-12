import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attachment_model.dart';
import '../../models/bimbingan_model.dart';
import '../../models/thesis_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../thesis/thesis_form_screen.dart';
import 'bimbingan_detail_screen.dart';
import 'bimbingan_form_screen.dart';
import 'thesis_links_screen.dart';

class BimbinganListScreen extends StatelessWidget {
  final ThesisModel thesis;
  const BimbinganListScreen({super.key, required this.thesis});
  void _showProfileSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.lavender,
                child: Text(
                  (auth.user?.name.isNotEmpty == true)
                      ? auth.user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(auth.user?.name ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(auth.user?.email ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_outlined,
                      color: AppColors.primary, size: 20),
                ),
                title: const Text('Edit Skripsi',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ThesisFormScreen(existing: thesis)));
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 20),
                ),
                title: const Text('Sign Out',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await auth.signOut();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bimbingan Skripsi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: GestureDetector(
          onTap: () => _showProfileSheet(context, auth),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CircleAvatar(
              backgroundColor: AppColors.lavender,
              child: Text(
                (auth.user?.name.isNotEmpty == true)
                    ? auth.user!.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BimbinganFormScreen(thesisId: thesis.id)),
        ),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Planning Bimbingan',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
        children: [
          _ThesisInfoCard(thesis: thesis),
          const SizedBox(height: 14),
          StreamBuilder<List<AttachmentModel>>(
            stream: fs.thesisLinksStream(thesis.id),
            builder: (context, snap) {
              final links = snap.data ?? [];
              return _QuickLinksCard(
                links: links,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ThesisLinksScreen(thesisId: thesis.id)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Daftar Bimbingan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<List<BimbinganModel>>(
            stream: fs.bimbinganStream(thesis.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return _EmptyBimbingan(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            BimbinganFormScreen(thesisId: thesis.id)),
                  ),
                );
              }
              return Column(
                children: items
                    .map((item) => _BimbinganCard(
                          bimbingan: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BimbinganDetailScreen(
                                  bimbingan: item, thesisId: thesis.id),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThesisInfoCard extends StatelessWidget {
  final ThesisModel thesis;
  const _ThesisInfoCard({required this.thesis});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF9B85FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  thesis.field.isNotEmpty ? thesis.field : 'Skripsi',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            thesis.title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (thesis.supervisorId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    thesis.supervisorId,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  final List<AttachmentModel> links;
  final VoidCallback onTap;
  const _QuickLinksCard({required this.links, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link_rounded,
                      size: 18, color: Color(0xFF7A5500)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tautan Penting',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(
                        links.isEmpty
                            ? 'Belum ada tautan — tap untuk tambah'
                            : '${links.length} tautan tersimpan',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
            if (links.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...links.take(3).map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            a.title,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          a.sourceHost,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )),
              if (links.length > 3)
                Text(
                  '+ ${links.length - 3} lainnya',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BimbinganCard extends StatelessWidget {
  final BimbinganModel bimbingan;
  final VoidCallback onTap;
  const _BimbinganCard({required this.bimbingan, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final planPreview = bimbingan.plan.length > 80
        ? '${bimbingan.plan.substring(0, 80)}…'
        : bimbingan.plan;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(bimbingan.date),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                  Text(
                    DateFormat('MMM').format(bimbingan.date),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bimbingan.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(bimbingan.date),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (planPreview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      planPreview,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _EmptyBimbingan extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyBimbingan({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.textLight.withValues(alpha: 0.4),
              style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 32),
            SizedBox(height: 10),
            Text('Belum ada bimbingan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Tap untuk catat sesi bimbingan pertama',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
