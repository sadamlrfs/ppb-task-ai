import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/gemma_provider.dart';
import '../../services/ai_service.dart';

const _kModelUrl = String.fromEnvironment(
  'GEMMA_MODEL_URL',
  defaultValue: '',
);

class ModelSetupScreen extends StatefulWidget {
  final VoidCallback? onReady;
  const ModelSetupScreen({super.key, this.onReady});
  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final _urlCtrl = TextEditingController(text: _kModelUrl);
  bool _showUrlField = false;
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndInit());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAndInit() async {
    final available = await AiService.instance.isModelAvailable();
    if (!mounted) return;
    if (available) {
      final gemma = context.read<GemmaProvider>();
      await gemma.initFromDisk();
      if (mounted && gemma.isReady) widget.onReady?.call();
    } else {
      await _tryCopyFromExternal();
    }
  }

  Future<void> _tryCopyFromExternal() async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) return;
      final sourceFile = File('${extDir.path}/model.bin');
      if (await sourceFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Menemukan model di penyimpanan eksternal, menyalin...')),
        );
        final destPath = await AiService.modelPath;
        await sourceFile.copy(destPath);
        final available = await AiService.instance.isModelAvailable();
        if (available && mounted) {
          final gemma = context.read<GemmaProvider>();
          await gemma.initFromDisk();
          if (mounted && gemma.isReady) widget.onReady?.call();
        }
      }
    } catch (e) {
      debugPrint('Failed to copy from external: $e');
    }
  }

  Future<void> _download() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan URL model terlebih dahulu')),
      );
      return;
    }
    final gemma = context.read<GemmaProvider>();
    await gemma.downloadAndInit(url);
    if (mounted && gemma.isReady) widget.onReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    final gemma = context.watch<GemmaProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildHero(gemma),
              const SizedBox(height: 32),
              _buildTitle(gemma),
              const SizedBox(height: 16),
              _buildDescription(gemma),
              const Spacer(flex: 1),
              if (gemma.isLoading) _buildProgressBar(gemma),
              if (!gemma.isLoading && !gemma.isReady) ...[
                _buildUrlSection(),
                const SizedBox(height: 14),
                _buildDownloadButton(gemma),
              ],
              if (gemma.isReady) _buildReadyBadge(),
              if (gemma.hasError) _buildErrorCard(gemma),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(GemmaProvider gemma) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gemma.isReady
                ? [const Color(0xFF34C759), const Color(0xFF30D158)]
                : gemma.hasError
                    ? [AppColors.error, const Color(0xFFFF6961)]
                    : [AppColors.primary, const Color(0xFF9B85FF)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (gemma.isReady
                      ? AppColors.success
                      : gemma.hasError
                          ? AppColors.error
                          : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Icon(
          gemma.isReady
              ? Icons.smart_toy_rounded
              : gemma.hasError
                  ? Icons.error_outline_rounded
                  : Icons.psychology_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }

  Widget _buildTitle(GemmaProvider gemma) {
    final text = gemma.isReady
        ? 'Model Siap!'
        : gemma.isLoading
            ? 'Mengunduh Model…'
            : gemma.hasError
                ? 'Gagal Memuat'
                : 'Setup Model AI';
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDescription(GemmaProvider gemma) {
    final text = gemma.isReady
        ? 'Gemma 2B berjalan sepenuhnya di perangkat Anda. Tidak ada data yang dikirim ke server.'
        : gemma.isLoading
            ? 'Model (~1.5 GB) sedang diunduh ke perangkat Anda. Proses ini hanya perlu dilakukan sekali.'
            : gemma.hasError
                ? 'Terjadi kesalahan saat memuat model. Periksa URL dan koneksi internet Anda.'
                : 'MyBimbingan menggunakan Gemma 2B yang berjalan sepenuhnya di perangkat Anda (on-device AI) — '
                    'privat dan bebas kuota.';
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildProgressBar(GemmaProvider gemma) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mengunduh Gemma 2B-IT…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${gemma.downloadPercent}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: gemma.downloadPercent / 100,
            minHeight: 10,
            backgroundColor: AppColors.lavender.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showUrlField = !_showUrlField),
          child: Row(
            children: [
              const Text(
                'URL Model (opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _showUrlField
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        if (_showUrlField) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lavender),
            ),
            child: TextField(
              controller: _urlCtrl,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'https://...',
                hintStyle: TextStyle(color: AppColors.textLight),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.link_rounded,
                    color: AppColors.textLight, size: 20),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadButton(GemmaProvider gemma) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: gemma.isLoading ? null : _download,
        icon: const Icon(Icons.download_rounded, size: 22),
        label: const Text(
          'Unduh & Aktifkan Model',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lavender,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildReadyBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          SizedBox(width: 10),
          Text(
            'Gemma 2B-IT aktif dan siap digunakan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(GemmaProvider gemma) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 18),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            gemma.lastError ?? 'Unknown error',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _download,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
