import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attachment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/custom_text_field.dart';

class AttachmentFormScreen extends StatefulWidget {
  final String thesisId;
  final String? bimbinganId;
  const AttachmentFormScreen({
    super.key,
    required this.thesisId,
    this.bimbinganId,
  });
  @override
  State<AttachmentFormScreen> createState() => _AttachmentFormScreenState();
}

class _AttachmentFormScreenState extends State<AttachmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  String _kind = 'link';
  bool _loading = false;
  static const _kinds = [
    ('link', Icons.link_rounded, 'Link'),
    ('video', Icons.play_circle_outline_rounded, 'Video'),
    ('image', Icons.image_outlined, 'Image'),
    ('audio', Icons.headphones_outlined, 'Audio'),
    ('doc', Icons.description_outlined, 'Document'),
  ];
  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final uid = context.read<AuthProvider>().user!.uid;
    try {
      final url = _urlCtrl.text.trim();
      final attachment = AttachmentModel(
        id: const Uuid().v4(),
        ownerId: uid,
        thesisId: widget.thesisId,
        bimbinganId: widget.bimbinganId,
        kind: _kind,
        url: url,
        title: _titleCtrl.text.trim().isEmpty
            ? AttachmentModel.hostFromUrl(url)
            : _titleCtrl.text.trim(),
        sourceHost: AttachmentModel.hostFromUrl(url),
        addedAt: DateTime.now(),
      );
      await FirestoreService().createAttachment(attachment);
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

  Future<void> _previewUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open URL')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Attachment'),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Paste a link from Google Drive, YouTube, Dropbox or any URL — no file upload needed.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kinds.map((k) {
                    final selected = _kind == k.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _kind = k.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(k.$2,
                                size: 16,
                                color: selected
                                    ? AppColors.surface
                                    : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(k.$3,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.surface
                                      : AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'URL',
                hint: 'https://drive.google.com/…',
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'URL is required';
                  final uri = Uri.tryParse(v);
                  if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                  return null;
                },
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: AppColors.primary, size: 20),
                  onPressed: _previewUrl,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Title (optional)',
                hint: 'e.g. Chapter 2 Draft',
                controller: _titleCtrl,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Add Attachment',
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
