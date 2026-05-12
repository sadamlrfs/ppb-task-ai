import 'package:cloud_firestore/cloud_firestore.dart';

class AttachmentModel {
  final String id;
  final String ownerId;
  final String thesisId;
  final String? bimbinganId;
  final String kind;
  final String url;
  final String title;
  final String sourceHost;
  final DateTime addedAt;
  const AttachmentModel({
    required this.id,
    required this.ownerId,
    required this.thesisId,
    this.bimbinganId,
    required this.kind,
    required this.url,
    required this.title,
    required this.sourceHost,
    required this.addedAt,
  });
  factory AttachmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AttachmentModel(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      thesisId: d['thesisId'] ?? '',
      bimbinganId: d['bimbinganId'],
      kind: d['kind'] ?? 'link',
      url: d['url'] ?? '',
      title: d['title'] ?? '',
      sourceHost: d['sourceHost'] ?? '',
      addedAt: (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'thesisId': thesisId,
        'bimbinganId': bimbinganId,
        'kind': kind,
        'url': url,
        'title': title,
        'sourceHost': sourceHost,
        'addedAt': Timestamp.fromDate(addedAt),
      };
  static String hostFromUrl(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return 'unknown';
    }
  }
}
