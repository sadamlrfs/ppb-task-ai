import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

const _kModelFile = 'model.bin';

enum GemmaState { idle, loading, ready, error }

class AiService {
  AiService._();
  static final AiService instance = AiService._();
  GemmaState _state = GemmaState.idle;
  String? _lastError;
  GemmaState get state => _state;
  String? get lastError => _lastError;
  static Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_kModelFile';
  }

  Future<bool> isModelAvailable() async => File(await modelPath).existsSync();
  Future<void> init({
    int maxTokens = 1024,
    double temperature = 0.8,
    int topK = 1,
    int randomSeed = 1,
  }) async {
    if (_state == GemmaState.ready) return;
    final loaded = await FlutterGemmaPlugin.instance.isLoaded;
    if (!loaded) {
      throw Exception(
        'model_not_available: copy model.bin to <documents>/model.bin first.',
      );
    }
    _state = GemmaState.loading;
    _lastError = null;
    try {
      await FlutterGemmaPlugin.instance.init(
        maxTokens: maxTokens,
        temperature: temperature,
        topK: topK,
        randomSeed: randomSeed,
      );
      _state = GemmaState.ready;
    } catch (e) {
      _state = GemmaState.error;
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> downloadModel(
    String url, {
    void Function(int percent)? onProgress,
    int maxTokens = 1024,
    double temperature = 0.8,
    int topK = 1,
    int randomSeed = 1,
  }) async {
    _state = GemmaState.loading;
    _lastError = null;
    try {
      await for (final pct in FlutterGemmaPlugin.instance
          .loadNetworkModelWithProgress(url: url)) {
        onProgress?.call(pct);
      }
      await FlutterGemmaPlugin.instance.init(
        maxTokens: maxTokens,
        temperature: temperature,
        topK: topK,
        randomSeed: randomSeed,
      );
      _state = GemmaState.ready;
    } catch (e) {
      _state = GemmaState.error;
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> close() async {
    if (_state != GemmaState.ready) return;
    await FlutterGemmaPlugin.instance.close();
    _state = GemmaState.idle;
  }

  void _assertReady() {
    if (_state != GemmaState.ready) {
      throw StateError(
        'AiService is not ready (state=$_state). Call init() first.',
      );
    }
  }

  static String _singleTurnPrompt(String userText) =>
      '<start_of_turn>user\n$userText<end_of_turn>\n<start_of_turn>model\n';
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'ISI_API_KEY_GEMINI_DI_SINI',
  );
  Future<String> summarizeNote(String text) async {
    if (_geminiApiKey.isEmpty ||
        _geminiApiKey == 'ISI_API_KEY_GEMINI_DI_SINI') {
      return 'Gagal: API Key Gemini belum diatur. Silakan isi API key di ai_service.dart atau jalankan dengan --dart-define=GEMINI_API_KEY=...';
    }
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );
      final prompt =
          'Kamu adalah asisten akademik yang membantu mahasiswa bimbingan skripsi. '
          'Buatkan ringkasan singkat dan jelas (maksimal 4 kalimat) dari catatan '
          'berikut dalam bahasa Indonesia. Fokus pada poin-poin utama dan '
          'kesimpulan penting:\n\n$text';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Tidak dapat membuat ringkasan.';
    } catch (e) {
      return 'Gagal meringkas dengan Gemini: $e';
    }
  }

  Stream<String?> summarizeNoteStream(String text) async* {
    if (_geminiApiKey.isEmpty ||
        _geminiApiKey == 'ISI_API_KEY_GEMINI_DI_SINI') {
      yield 'Gagal: API Key Gemini belum diatur.';
      return;
    }
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );
      final prompt =
          'Kamu adalah asisten akademik yang membantu mahasiswa bimbingan skripsi. '
          'Buatkan ringkasan singkat dan jelas (maksimal 4 kalimat) dari catatan '
          'berikut dalam bahasa Indonesia. Fokus pada poin-poin utama dan '
          'kesimpulan penting:\n\n$text';
      await for (final chunk
          in model.generateContentStream([Content.text(prompt)])) {
        yield chunk.text;
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  Future<String> analyzeHandwriting(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);
    String extractedText = '';
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final recognized = await textRecognizer.processImage(inputImage);
      extractedText = recognized.text.trim();
    } finally {
      await textRecognizer.close();
      if (await tempFile.exists()) await tempFile.delete();
    }
    if (extractedText.isEmpty) {
      return 'Tidak dapat membaca teks dari gambar.';
    }
    if (_geminiApiKey.isEmpty ||
        _geminiApiKey == 'ISI_API_KEY_GEMINI_DI_SINI') {
      return '**Teks yang terbaca:**\n$extractedText\n\n**Penjelasan:**\n'
          '(API Key Gemini belum diatur. Silakan isi di ai_service.dart)';
    }
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );
      final prompt =
          'Kamu adalah asisten akademik. Berikut adalah teks yang dibaca dari '
          'sebuah gambar:\n\n"$extractedText"\n\n'
          'Berikan penjelasan singkat tentang isi teks tersebut dalam bahasa '
          'Indonesia.';
      final response = await model.generateContent([Content.text(prompt)]);
      final explanationText =
          response.text?.trim() ?? 'Tidak dapat membuat penjelasan.';
      return '**Teks yang terbaca:**\n$extractedText\n\n**Penjelasan:**\n$explanationText';
    } catch (e) {
      return '**Teks yang terbaca:**\n$extractedText\n\n**Penjelasan:**\n'
          '(Gagal menghubungi Gemini API: $e)';
    }
  }
}
