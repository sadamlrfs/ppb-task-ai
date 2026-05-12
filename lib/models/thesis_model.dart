import 'package:cloud_firestore/cloud_firestore.dart';

class ThesisModel {
  final String id;
  final String title;
  final String abstract;
  final String field;
  final String studentId;
  final String supervisorId;
  final String status;
  final DateTime startDate;
  final DateTime targetDate;
  const ThesisModel({
    required this.id,
    required this.title,
    required this.abstract,
    required this.field,
    required this.studentId,
    required this.supervisorId,
    required this.status,
    required this.startDate,
    required this.targetDate,
  });
  factory ThesisModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ThesisModel(
      id: doc.id,
      title: d['title'] ?? '',
      abstract: d['abstract'] ?? '',
      field: d['field'] ?? '',
      studentId: d['studentId'] ?? '',
      supervisorId: d['supervisorId'] ?? '',
      status: d['status'] ?? 'planning',
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetDate: (d['targetDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 180)),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'abstract': abstract,
        'field': field,
        'studentId': studentId,
        'supervisorId': supervisorId,
        'status': status,
        'startDate': Timestamp.fromDate(startDate),
        'targetDate': Timestamp.fromDate(targetDate),
      };
  ThesisModel copyWith({
    String? title,
    String? abstract,
    String? field,
    String? supervisorId,
    String? status,
    DateTime? targetDate,
  }) =>
      ThesisModel(
        id: id,
        title: title ?? this.title,
        abstract: abstract ?? this.abstract,
        field: field ?? this.field,
        studentId: studentId,
        supervisorId: supervisorId ?? this.supervisorId,
        status: status ?? this.status,
        startDate: startDate,
        targetDate: targetDate ?? this.targetDate,
      );
}
