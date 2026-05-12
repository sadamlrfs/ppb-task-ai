import 'package:cloud_firestore/cloud_firestore.dart';

class BimbinganModel {
  final String id;
  final String thesisId;
  final String title;
  final String plan;
  final DateTime date;
  final DateTime createdAt;
  const BimbinganModel({
    required this.id,
    required this.thesisId,
    required this.title,
    this.plan = '',
    required this.date,
    required this.createdAt,
  });
  factory BimbinganModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BimbinganModel(
      id: doc.id,
      thesisId: d['thesisId'] ?? '',
      title: d['title'] ?? '',
      plan: d['plan'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'thesisId': thesisId,
        'title': title,
        'plan': plan,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };
  BimbinganModel copyWith({String? title, String? plan, DateTime? date}) =>
      BimbinganModel(
        id: id,
        thesisId: thesisId,
        title: title ?? this.title,
        plan: plan ?? this.plan,
        date: date ?? this.date,
        createdAt: createdAt,
      );
}
