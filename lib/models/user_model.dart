import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? photoURL;
  final DateTime createdAt;
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoURL,
    required this.createdAt,
  });
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      role: d['role'] ?? 'student',
      photoURL: d['photoURL'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'role': role,
        'photoURL': photoURL,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
