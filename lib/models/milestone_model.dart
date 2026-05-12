import 'package:cloud_firestore/cloud_firestore.dart';

class MilestoneModel {
  final String id;
  final String thesisId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? completedAt;
  final int order;
  final String status;
  const MilestoneModel({
    required this.id,
    required this.thesisId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.completedAt,
    required this.order,
    required this.status,
  });
  factory MilestoneModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MilestoneModel(
      id: doc.id,
      thesisId: d['thesisId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      order: d['order'] ?? 0,
      status: d['status'] ?? 'pending',
    );
  }
  Map<String, dynamic> toFirestore() => {
        'thesisId': thesisId,
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'order': order,
        'status': status,
      };
  bool get isOverdue =>
      status != 'completed' && dueDate.isBefore(DateTime.now());
}
