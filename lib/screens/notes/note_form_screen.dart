import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gemma_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../settings/model_setup_screen.dart';

class NoteFormScreen extends StatefulWidget {
  final String thesisId;
  final String? bimbinganId;
  final NoteModel? existing;
  const NoteFormScreen({
    super.key,
    required this.thesisId,
    this.bimbinganId,
    this.existing,
  });
  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _bodyCtrl = TextEditingController();
  bool _loading = false;
  bool _aiLoading = false;
  bool _scanLoading = false;
  bool get _isEdit => widget.existing != null;
  @override
  void initState() {
    super.initState();
    if (_isEdit) _bodyCtrl.text = widget.existing!.body;
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty')),
      );
      return;
    }
    setState(() => _loading = true);
    final uid = context.read<AuthProvider>().user!.uid;
    final fs = FirestoreService();
    try {
      if (_isEdit) {
        final updated = NoteModel(
          id: widget.existing!.id,
          thesisId: widget.thesisId,
          bimbinganId: widget.bimbinganId,
          authorId: uid,
          body: _bodyCtrl.text.trim(),
          createdAt: widget.existing!.createdAt,
        );
        await fs.updateNote(updated);
      } else {
        await fs.createNote(NoteModel(
          id: const Uuid().v4(),
          thesisId: widget.thesisId,
          bimbinganId: widget.bimbinganId,
          authorId: uid,
          body: _bodyCtrl.text.trim(),
          createdAt: DateTime.now(),
        ));
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

  Future<void> _summarizeNote() async {
    if (_bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis catatan terlebih dahulu')),
      );
      return;
    }
    final gemma = context.read<GemmaProvider>();
    setState(() => _aiLoading = true);
    try {
      final summary = await gemma.summarizeNote(_bodyCtrl.text.trim());
      if (!mounted) return;
      _showAiResultSheet(
        title: 'Ringkasan AI',
        icon: Icons.auto_awesome_rounded,
        content: summary,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meringkas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _scanHandwriting() async {
    final source = await _showSourcePicker();
    if (source == null || !mounted) return;
    setState(() => _scanLoading = true);
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source, imageQuality: 85);
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      final gemma = context.read<GemmaProvider>();
      final result = await gemma.analyzeHandwriting(bytes);
      if (!mounted) return;
      _showAiResultSheet(
        title: 'Hasil Scan Tulisan',
        icon: Icons.document_scanner_rounded,
        content: result,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membaca gambar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanLoading = false);
    }
  }

  void _showModelNotReadyDialog(GemmaProvider gemma) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Model AI Belum Siap',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          gemma.hasError
              ? 'Terjadi kesalahan: ${gemma.lastError}'
              : gemma.isLoading
                  ? 'Model sedang dimuat, harap tunggu…'
                  : 'Model Gemma belum diinisialisasi.\n\n'
                      'Pastikan file model.bin sudah tersalin ke '
                      'direktori dokumen aplikasi, lalu inisialisasi '
                      'dari halaman pengaturan.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(_);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModelSetupScreen(
                    onReady: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Setup Model'),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _showSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Gambar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Foto tulisan langsung'),
              onTap: () => Navigator.pop(_, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih dari foto tersimpan'),
              onTap: () => Navigator.pop(_, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAiResultSheet({
    required String title,
    required IconData icon,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiResultSheet(
        title: title,
        icon: icon,
        content: content,
        onReplace: () {
          _bodyCtrl.text = content;
          Navigator.pop(_);
        },
        onAppend: () {
          final current = _bodyCtrl.text.trim();
          _bodyCtrl.text = current.isEmpty ? content : '$current\n\n$content';
          Navigator.pop(_);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Note' : 'New Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_scanLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.document_scanner_rounded),
              tooltip: 'Scan Tulisan Tangan',
              onPressed: _scanHandwriting,
            ),
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: () async {
                await FirestoreService().deleteNote(widget.existing!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan di sini…',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppColors.textLight),
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: (_aiLoading || _loading) ? null : _summarizeNote,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _aiLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Ringkas dengan AI',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: _isEdit ? 'Save Changes' : 'Save Note',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AiResultSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final VoidCallback onReplace;
  final VoidCallback onAppend;
  const _AiResultSheet({
    required this.title,
    required this.icon,
    required this.content,
    required this.onReplace,
    required this.onAppend,
  });
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Tambahkan'),
                          onPressed: onAppend,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text('Ganti Teks'),
                          onPressed: onReplace,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
