import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const _apiKey = 'AIzaSyCMwQYVVslZugAEHwNwnEM7S42wT4fPH4c';

  final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );

  Future<String> summarizeNote(String text) async {
    final prompt =
        'Kamu adalah asisten akademik yang membantu mahasiswa bimbingan skripsi. '
        'Buatkan ringkasan singkat dan jelas (maksimal 4 kalimat) dari catatan berikut '
        'dalam bahasa Indonesia. Fokus pada poin-poin utama dan kesimpulan penting:\n\n'
        '$text';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? 'Tidak dapat membuat ringkasan.';
  }

  Future<String> analyzeHandwriting(Uint8List imageBytes) async {
    final content = Content.multi([
      TextPart(
        'Kamu adalah asisten akademik. Baca semua tulisan tangan atau teks yang '
        'ada dalam gambar ini, lalu berikan transkripsi lengkap dan penjelasannya '
        'dalam bahasa Indonesia.\n\n'
        'Format respons:\n'
        '**Teks yang terbaca:**\n'
        '[tuliskan semua teks dari gambar]\n\n'
        '**Penjelasan:**\n'
        '[penjelasan singkat tentang isi tulisan tersebut]',
      ),
      DataPart('image/jpeg', imageBytes),
    ]);
    final response = await _model.generateContent([content]);
    return response.text?.trim() ?? 'Tidak dapat membaca gambar.';
  }
}
