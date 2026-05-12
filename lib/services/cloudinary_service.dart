import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = 'dbxavn3pl';
  static const _apiKey = '881464176752834';
  static const _apiSecret = '__Rv-HcSWFPvoWRGSpEZePt766I';
  static Future<String> upload(String filePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signature = _sign('timestamp=$timestamp');
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = _apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json.containsKey('error')) {
      throw Exception('Cloudinary: ${json['error']['message']}');
    }
    return json['secure_url'] as String;
  }

  static String _sign(String params) {
    final bytes = utf8.encode('$params$_apiSecret');
    return sha1.convert(bytes).toString();
  }
}
