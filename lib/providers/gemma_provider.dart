import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';

class GemmaProvider extends ChangeNotifier {
  final AiService _ai = AiService.instance;
  GemmaState get state => _ai.state;
  String? get lastError => _ai.lastError;
  bool get isIdle => _ai.state == GemmaState.idle;
  bool get isLoading => _ai.state == GemmaState.loading;
  bool get isReady => _ai.state == GemmaState.ready;
  bool get hasError => _ai.state == GemmaState.error;
  int _downloadPercent = 0;
  int get downloadPercent => _downloadPercent;
  Future<void> initFromDisk() async {
    try {
      await _ai.init();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> downloadAndInit(String url) async {
    _downloadPercent = 0;
    notifyListeners();
    try {
      await _ai.downloadModel(
        url,
        onProgress: (pct) {
          _downloadPercent = pct;
          notifyListeners();
        },
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> close() async {
    await _ai.close();
    notifyListeners();
  }

  Future<String> summarizeNote(String text) => _ai.summarizeNote(text);
  Stream<String?> summarizeNoteStream(String text) =>
      _ai.summarizeNoteStream(text);
  Future<String> analyzeHandwriting(List<int> bytes) =>
      _ai.analyzeHandwriting(Uint8List.fromList(bytes));
}
