import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attachment_model.dart';
import '../../models/bimbingan_model.dart';
import '../../models/media_model.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';
import '../../services/media_service.dart';
import '../../widgets/section_header.dart';
import '../attachments/attachment_form_screen.dart';
import '../media/video_player_screen.dart';
import '../media/voice_recorder_screen.dart';
import '../notes/note_form_screen.dart';
import 'bimbingan_form_screen.dart';
import 'voice_notulen_screen.dart';

class BimbinganDetailScreen extends StatefulWidget {
  final BimbinganModel bimbingan;
  final String thesisId;
  const BimbinganDetailScreen({
    super.key,
    required this.bimbingan,
    required this.thesisId,
  });
  @override
  State<BimbinganDetailScreen> createState() => _BimbinganDetailScreenState();
}

class _BimbinganDetailScreenState extends State<BimbinganDetailScreen> {
  final _mediaService = MediaService();
  final _fs = FirestoreService();
  String _currentUid() => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  Future<void> _capturePhoto() async {
    try {
      final file = await _mediaService.capturePhoto();
      if (file == null || !mounted) return;
      _showUploadingSnack();
      final url = await _mediaService.uploadFile(file.path);
      await _mediaService.saveMedia(MediaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        thesisId: widget.thesisId,
        bimbinganId: widget.bimbingan.id,
        authorId: _currentUid(),
        type: 'photo',
        cloudinaryUrl: url,
        capturedAt: DateTime.now(),
      ));
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _captureVideo() async {
    try {
      final file = await _mediaService.captureVideo();
      if (file == null || !mounted) return;
      _showUploadingSnack();
      final url = await _mediaService.uploadFile(file.path);
      await _mediaService.saveMedia(MediaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        thesisId: widget.thesisId,
        bimbinganId: widget.bimbingan.id,
        authorId: _currentUid(),
        type: 'video',
        cloudinaryUrl: url,
        capturedAt: DateTime.now(),
      ));
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUploadingSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)),
          SizedBox(width: 14),
          Text('Mengupload ke Cloudinary…'),
        ]),
        duration: Duration(minutes: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.bimbingan.title,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BimbinganFormScreen(
                  thesisId: widget.thesisId,
                  existing: widget.bimbingan,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
        children: [
          _HeaderCard(bimbingan: widget.bimbingan),
          const SizedBox(height: 20),
          _ActionRow(
            onNote: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteFormScreen(
                  thesisId: widget.thesisId,
                  bimbinganId: widget.bimbingan.id,
                ),
              ),
            ),
            onNotulen: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VoiceNotulenScreen(
                  thesisId: widget.thesisId,
                  bimbinganId: widget.bimbingan.id,
                ),
              ),
            ),
            onPhoto: _capturePhoto,
            onVideo: _captureVideo,
            onVoice: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VoiceRecorderScreen(
                  thesisId: widget.thesisId,
                  bimbinganId: widget.bimbingan.id,
                ),
              ),
            ),
            onLink: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttachmentFormScreen(
                  thesisId: widget.thesisId,
                  bimbinganId: widget.bimbingan.id,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Catatan'),
          const SizedBox(height: 12),
          StreamBuilder<List<NoteModel>>(
            stream: _fs.notesForBimbingan(widget.bimbingan.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2));
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              final notes = snap.data ?? [];
              if (notes.isEmpty) {
                return _EmptyHint(
                  icon: Icons.note_alt_outlined,
                  label: 'Belum ada catatan',
                );
              }
              return Column(
                children: notes
                    .map((n) => _NoteCard(
                          note: n,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteFormScreen(
                                thesisId: widget.thesisId,
                                bimbinganId: widget.bimbingan.id,
                                existing: n,
                              ),
                            ),
                          ),
                          onDelete: () => _fs.deleteNote(n.id),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Media'),
          const SizedBox(height: 12),
          StreamBuilder<List<MediaModel>>(
            stream: _mediaService.mediaForBimbingan(widget.bimbingan.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2));
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return _EmptyHint(
                  icon: Icons.perm_media_outlined,
                  label: 'Belum ada media',
                );
              }
              final photos = items
                  .where((m) => m.type == 'photo' || m.type == 'video')
                  .toList();
              final voices = items.where((m) => m.type == 'voice').toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photos.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (_, i) =>
                          _MediaTile(media: photos[i], service: _mediaService),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (voices.isNotEmpty)
                    ...voices.map(
                        (v) => _VoiceTile(media: v, service: _mediaService)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Tautan'),
          const SizedBox(height: 12),
          StreamBuilder<List<AttachmentModel>>(
            stream: _fs.attachmentsForBimbingan(widget.bimbingan.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2));
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              final links = snap.data ?? [];
              if (links.isEmpty) {
                return _EmptyHint(
                  icon: Icons.link_rounded,
                  label: 'Belum ada tautan',
                );
              }
              return Column(
                children: links
                    .map((a) => _AttachmentCard(
                          attachment: a,
                          onDelete: () => _fs.deleteAttachment(a.id),
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

class _HeaderCard extends StatelessWidget {
  final BimbinganModel bimbingan;
  const _HeaderCard({required this.bimbingan});
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(bimbingan.date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rencana',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          bimbingan.plan.isNotEmpty
              ? Text(
                  bimbingan.plan,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                )
              : const Text(
                  'Tidak ada rencana',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onNote;
  final VoidCallback onNotulen;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onVoice;
  final VoidCallback onLink;
  const _ActionRow({
    required this.onNote,
    required this.onNotulen,
    required this.onPhoto,
    required this.onVideo,
    required this.onVoice,
    required this.onLink,
  });
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.note_alt_outlined, 'Catatan', onNote),
      (Icons.record_voice_over_rounded, 'Notulen', onNotulen),
      (Icons.camera_alt_rounded, 'Foto', onPhoto),
      (Icons.videocam_rounded, 'Video', onVideo),
      (Icons.mic_rounded, 'Suara', onVoice),
      (Icons.link_rounded, 'Tautan', onLink),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return _ActionButton(icon: a.$1, label: a.$2, onTap: a.$3);
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                note.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textLight, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaModel media;
  final MediaService service;
  const _MediaTile({required this.media, required this.service});
  Future<void> _open(BuildContext context) async {
    if (media.type == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(url: media.cloudinaryUrl),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PhotoViewer(url: media.cloudinaryUrl),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Media'),
        content: const Text('File ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) await service.deleteMedia(media);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      onLongPress: () => _confirmDelete(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.type == 'photo' && media.cloudinaryUrl.isNotEmpty)
              Image.network(media.cloudinaryUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: AppColors.dark,
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.white, size: 28)))
            else
              Container(
                color: AppColors.dark,
                child: const Icon(Icons.play_circle_filled_rounded,
                    color: Colors.white, size: 36),
              ),
            if (media.type == 'video')
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const CircularProgressIndicator(color: Colors.white)),
        ),
      ),
    );
  }
}

class _VoiceTile extends StatefulWidget {
  final MediaModel media;
  final MediaService service;
  const _VoiceTile({required this.media, required this.service});
  @override
  State<_VoiceTile> createState() => _VoiceTileState();
}

class _VoiceTileState extends State<_VoiceTile> {
  final _player = AudioPlayer();
  bool _playing = false;
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(UrlSource(widget.media.cloudinaryUrl));
      setState(() => _playing = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voice Note',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${widget.media.durationLabel}  ·  ${DateFormat('d MMM, HH:mm').format(widget.media.capturedAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textLight, size: 20),
            onPressed: () => widget.service.deleteMedia(widget.media),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback onDelete;
  const _AttachmentCard({required this.attachment, required this.onDelete});
  IconData _kindIcon(String kind) {
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

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.tryParse(attachment.url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak ada aplikasi yang bisa membuka tautan ini')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka tautan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launch(context),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_kindIcon(attachment.kind),
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attachment.sourceHost,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textLight, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyHint({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.textLight),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
