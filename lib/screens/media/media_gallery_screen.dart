import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'video_player_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../models/media_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/media_service.dart';
import 'voice_recorder_screen.dart';

class MediaGalleryScreen extends StatefulWidget {
  final String thesisId;
  final String thesisTitle;
  const MediaGalleryScreen({
    super.key,
    required this.thesisId,
    required this.thesisTitle,
  });
  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  final _mediaService = MediaService();
  Future<void> _capturePhoto() async {
    try {
      final file = await _mediaService.capturePhoto();
      if (file == null || !mounted) return;
      final url = await CloudinaryService.upload(file.path);
      await _mediaService.saveMedia(MediaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        thesisId: widget.thesisId,
        authorId: _currentUid(),
        type: 'photo',
        cloudinaryUrl: url,
        capturedAt: DateTime.now(),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save photo: $e')),
        );
      }
    }
  }

  Future<void> _captureVideo() async {
    try {
      final file = await _mediaService.captureVideo();
      if (file == null || !mounted) return;
      final url = await CloudinaryService.upload(file.path);
      await _mediaService.saveMedia(MediaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        thesisId: widget.thesisId,
        authorId: _currentUid(),
        type: 'video',
        cloudinaryUrl: url,
        capturedAt: DateTime.now(),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save video: $e')),
        );
      }
    }
  }

  String _currentUid() => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.camera_alt_rounded,
                iconBg: AppColors.lavender,
                iconColor: AppColors.primary,
                label: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _capturePhoto();
                },
              ),
              _OptionTile(
                icon: Icons.videocam_rounded,
                iconBg: AppColors.yellow,
                iconColor: const Color(0xFF7A5500),
                label: 'Record Video',
                onTap: () {
                  Navigator.pop(context);
                  _captureVideo();
                },
              ),
              _OptionTile(
                icon: Icons.mic_rounded,
                iconBg: AppColors.cardLight,
                iconColor: AppColors.primary,
                label: 'Voice Note',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoiceRecorderScreen(
                        thesisId: widget.thesisId,
                      ),
                    ),
                  );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Media'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showOptions,
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Media',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<MediaModel>>(
        stream: _mediaService.mediaStream(widget.thesisId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error loading media: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
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
                    child: const Icon(Icons.perm_media_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('No media yet',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Tap + to add photos, videos or voice notes',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          final photos = items
              .where((m) => m.type == 'photo' || m.type == 'video')
              .toList();
          final voices = items.where((m) => m.type == 'voice').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
            children: [
              if (photos.isNotEmpty) ...[
                const Text('Photos & Videos',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (_, i) =>
                      _MediaTile(media: photos[i], service: _mediaService),
                ),
                const SizedBox(height: 24),
              ],
              if (voices.isNotEmpty) ...[
                const Text('Voice Notes',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...voices
                    .map((v) => _VoiceTile(media: v, service: _mediaService)),
              ],
            ],
          );
        },
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

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Media'),
        content: const Text('This will permanently delete this file.'),
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
    if (ok == true) await service.deleteMedia(media);
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
        borderRadius: BorderRadius.circular(16),
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
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
