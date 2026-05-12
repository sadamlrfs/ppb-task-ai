import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String thesisId;
  final String? bimbinganId;
  final String authorId;
  final String body;
  final DateTime createdAt;
  const NoteModel({
    required this.id,
    required this.thesisId,
    this.bimbinganId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });
  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      thesisId: d['thesisId'] ?? '',
      bimbinganId: d['bimbinganId'],
      authorId: d['authorId'] ?? '',
      body: d['body'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'thesisId': thesisId,
        'bimbinganId': bimbinganId,
        'authorId': authorId,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
