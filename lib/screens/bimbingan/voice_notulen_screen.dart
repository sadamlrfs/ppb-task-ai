import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class VoiceNotulenScreen extends StatefulWidget {
  final String thesisId;
  final String bimbinganId;
  const VoiceNotulenScreen({
    super.key,
    required this.thesisId,
    required this.bimbinganId,
  });
  @override
  State<VoiceNotulenScreen> createState() => _VoiceNotulenScreenState();
}

class _VoiceNotulenScreenState extends State<VoiceNotulenScreen> {
  final _speech = SpeechToText();
  final _editCtrl = TextEditingController();
  bool _speechAvailable = false;
  bool _listening = false;
  bool _saving = false;
  String _liveWords = '';
  String _localeId = 'id_ID';
  static const _locales = [
    ('id_ID', '🇮🇩  Indonesia'),
    ('en_US', '🇺🇸  English'),
  ];
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      setState(() {
        _listening = false;
        if (_liveWords.isNotEmpty) {
          final existing = _editCtrl.text;
          _editCtrl.text =
              existing.isEmpty ? _liveWords : '$existing\n$_liveWords';
          _editCtrl.selection =
              TextSelection.collapsed(offset: _editCtrl.text.length);
          _liveWords = '';
        }
      });
    } else {
      setState(() {
        _listening = true;
        _liveWords = '';
      });
      await _speech.listen(
        localeId: _localeId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 4),
        onResult: (result) {
          if (mounted) {
            setState(() => _liveWords = result.recognizedWords);
            if (result.finalResult) {
              final existing = _editCtrl.text;
              _editCtrl.text = existing.isEmpty
                  ? result.recognizedWords
                  : '$existing\n${result.recognizedWords}';
              _editCtrl.selection =
                  TextSelection.collapsed(offset: _editCtrl.text.length);
              _liveWords = '';
            }
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
        ),
      );
    }
  }

  Future<void> _save() async {
    final text = _editCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks notulen kosong')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      await FirestoreService().createNote(NoteModel(
        id: const Uuid().v4(),
        thesisId: widget.thesisId,
        bimbinganId: widget.bimbinganId,
        authorId: uid,
        body: text,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _editCtrl.text.isNotEmpty || _liveWords.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Auto Notulen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _localeId,
            onSelected: (v) => setState(() => _localeId = v),
            icon: const Icon(Icons.language_rounded),
            itemBuilder: (_) => _locales
                .map((l) => PopupMenuItem(value: l.$1, child: Text(l.$2)))
                .toList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _listening
                    ? AppColors.error.withValues(alpha: 0.1)
                    : _speechAvailable
                        ? AppColors.lavender
                        : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _listening
                        ? Icons.graphic_eq_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: _listening ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _listening
                          ? 'Sedang mendengarkan… bicara sekarang'
                          : _speechAvailable
                              ? 'Tap tombol mikrofon untuk mulai merekam suara'
                              : 'Speech recognition tidak tersedia di perangkat ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: _listening ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_listening && _liveWords.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _liveWords,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _editCtrl,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.7,
                        ),
                        decoration: InputDecoration(
                          hintText: hasText
                              ? null
                              : 'Hasil transkripsi akan muncul di sini…\nAnda juga bisa ketik langsung.',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(
                              color: AppColors.textLight, fontSize: 14),
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _speechAvailable ? _toggleListen : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _listening ? 80 : 72,
                height: _listening ? 80 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? AppColors.error : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_listening ? AppColors.error : AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: _listening ? 20 : 10,
                      spreadRadius: _listening ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _listening ? 'Tap untuk berhenti' : 'Tap untuk mulai',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (hasText && !_saving && !_listening) ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.textLight.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Menyimpan…' : 'Simpan sebagai Catatan',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
