import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/media_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/media_service.dart';

class VoiceRecorderScreen extends StatefulWidget {
  final String thesisId;
  final String? bimbinganId;
  const VoiceRecorderScreen({
    super.key,
    required this.thesisId,
    this.bimbinganId,
  });
  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _saving = false;
  String? _recordedPath;
  int _elapsed = 0;
  Timer? _timer;
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;
  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _playPosition = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _playDuration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/thesis_media/voice');
    if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
    final path = '${audioDir.path}/${const Uuid().v4()}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _elapsed = 0;
      _recordedPath = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });
  }

  Future<void> _togglePlayback() async {
    if (_recordedPath == null) return;
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(_recordedPath!));
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _discard() async {
    await _player.stop();
    if (_recordedPath != null) {
      final f = File(_recordedPath!);
      if (f.existsSync()) f.deleteSync();
    }
    setState(() {
      _recordedPath = null;
      _elapsed = 0;
      _isPlaying = false;
    });
  }

  Future<void> _save() async {
    if (_recordedPath == null) return;
    setState(() => _saving = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final url = await CloudinaryService.upload(_recordedPath!);
      final f = File(_recordedPath!);
      if (f.existsSync()) f.deleteSync();
      await MediaService().saveMedia(MediaModel(
        id: const Uuid().v4(),
        thesisId: widget.thesisId,
        bimbinganId: widget.bimbinganId,
        authorId: uid,
        type: 'voice',
        cloudinaryUrl: url,
        durationSeconds: _elapsed,
        capturedAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recording: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatSeconds(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voice Note'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isRecording ? 160 : 130,
              height: _isRecording ? 160 : 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.lavender,
                border: Border.all(
                  color: _isRecording ? AppColors.error : AppColors.primary,
                  width: 3,
                ),
              ),
              child: Icon(
                _isRecording
                    ? Icons.mic_rounded
                    : _recordedPath != null
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_none_rounded,
                size: 64,
                color: _isRecording ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _formatSeconds(_elapsed),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'Recording…'
                  : _recordedPath != null
                      ? 'Recording complete'
                      : 'Tap to start recording',
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            if (_recordedPath != null && !_isRecording) ...[
              Row(
                children: [
                  Text(
                    _formatSeconds(_playPosition.inSeconds),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Expanded(
                    child: Slider(
                      value: _playPosition.inSeconds
                          .toDouble()
                          .clamp(0, _playDuration.inSeconds.toDouble()),
                      max: _playDuration.inSeconds
                          .toDouble()
                          .clamp(1, double.infinity),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.textLight,
                      onChanged: (v) {
                        _player.seek(Duration(seconds: v.toInt()));
                      },
                    ),
                  ),
                  Text(
                    _formatSeconds(_playDuration.inSeconds),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_recordedPath != null && !_isRecording) ...[
                  _CircleBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error.withValues(alpha: 0.12),
                    iconColor: AppColors.error,
                    onTap: _discard,
                  ),
                  const SizedBox(width: 16),
                  _CircleBtn(
                    icon: _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppColors.lavender,
                    iconColor: AppColors.primary,
                    size: 64,
                    iconSize: 32,
                    onTap: _togglePlayback,
                  ),
                  const SizedBox(width: 16),
                  _CircleBtn(
                    icon: Icons.check_rounded,
                    color: AppColors.success.withValues(alpha: 0.15),
                    iconColor: AppColors.success,
                    onTap: _saving ? null : _save,
                    loading: _saving,
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isRecording ? AppColors.error : AppColors.primary,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool loading;
  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.iconColor,
    this.onTap,
    this.size = 52,
    this.iconSize = 24,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
