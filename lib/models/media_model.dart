import 'package:cloud_firestore/cloud_firestore.dart';

class MediaModel {
  final String id;
  final String thesisId;
  final String? bimbinganId;
  final String authorId;
  final String type;
  final String cloudinaryUrl;
  final int? durationSeconds;
  final DateTime capturedAt;
  const MediaModel({
    required this.id,
    required this.thesisId,
    this.bimbinganId,
    required this.authorId,
    required this.type,
    required this.cloudinaryUrl,
    this.durationSeconds,
    required this.capturedAt,
  });
  factory MediaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MediaModel(
      id: doc.id,
      thesisId: d['thesisId'] ?? '',
      bimbinganId: d['bimbinganId'],
      authorId: d['authorId'] ?? '',
      type: d['type'] ?? 'photo',
      cloudinaryUrl: d['cloudinaryUrl'] ?? d['localPath'] ?? '',
      durationSeconds: d['durationSeconds'],
      capturedAt: (d['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'thesisId': thesisId,
        'bimbinganId': bimbinganId,
        'authorId': authorId,
        'type': type,
        'cloudinaryUrl': cloudinaryUrl,
        'durationSeconds': durationSeconds,
        'capturedAt': Timestamp.fromDate(capturedAt),
      };
  String get durationLabel {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
