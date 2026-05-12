import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attachment_model.dart';
import '../../services/firestore_service.dart';
import '../attachments/attachment_form_screen.dart';

class ThesisLinksScreen extends StatelessWidget {
  final String thesisId;
  const ThesisLinksScreen({super.key, required this.thesisId});
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

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tautan Penting'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttachmentFormScreen(thesisId: thesisId),
          ),
        ),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Tautan',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<AttachmentModel>>(
        stream: fs.thesisLinksStream(thesisId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: AppColors.error)));
          }
          final links = snap.data ?? [];
          if (links.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.link_rounded,
                        size: 34, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada tautan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Simpan link penting skripsimu di sini',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
            itemCount: links.length,
            itemBuilder: (_, i) {
              final a = links[i];
              return GestureDetector(
                onTap: () => _launch(a.url),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_iconFor(a.kind),
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(a.sourceHost,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.textLight, size: 20),
                        onPressed: () => fs.deleteAttachment(a.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
