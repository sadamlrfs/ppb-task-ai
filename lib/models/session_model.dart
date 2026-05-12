import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String thesisId;
  final DateTime scheduledAt;
  final int durationMin;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final String status;
  final String summary;
  final List<String> actionItems;
  const SessionModel({
    required this.id,
    required this.thesisId,
    required this.scheduledAt,
    required this.durationMin,
    this.latitude,
    this.longitude,
    this.locationLabel,
    required this.status,
    required this.summary,
    required this.actionItems,
  });
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      thesisId: d['thesisId'] ?? '',
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMin: d['durationMin'] ?? 60,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      locationLabel: d['locationLabel'],
      status: d['status'] ?? 'scheduled',
      summary: d['summary'] ?? '',
      actionItems: List<String>.from(d['actionItems'] ?? []),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'thesisId': thesisId,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'durationMin': durationMin,
        'latitude': latitude,
        'longitude': longitude,
        'locationLabel': locationLabel,
        'status': status,
        'summary': summary,
        'actionItems': actionItems,
      };
  bool get hasLocation => latitude != null && longitude != null;
  String get locationDisplay => hasLocation
      ? (locationLabel ??
          '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}')
      : 'No location';
}
