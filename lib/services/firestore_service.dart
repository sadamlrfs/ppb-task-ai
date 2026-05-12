import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/thesis_model.dart';
import '../models/milestone_model.dart';
import '../models/session_model.dart';
import '../models/note_model.dart';
import '../models/attachment_model.dart';
import '../models/bimbingan_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  Stream<List<ThesisModel>> thesesStream(String userId) => _db
      .collection('theses')
      .where('studentId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map(ThesisModel.fromFirestore).toList());
  Future<ThesisModel> createThesis(ThesisModel thesis) async {
    final ref = await _db.collection('theses').add(thesis.toFirestore());
    final doc = await ref.get();
    return ThesisModel.fromFirestore(doc);
  }

  Future<void> updateThesis(ThesisModel thesis) =>
      _db.collection('theses').doc(thesis.id).update(thesis.toFirestore());
  Future<void> deleteThesis(String id) =>
      _db.collection('theses').doc(id).delete();
  Stream<List<MilestoneModel>> milestonesStream(String thesisId) => _db
          .collection('milestones')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(MilestoneModel.fromFirestore).toList();
        list.sort((a, b) => a.order.compareTo(b.order));
        return list;
      });
  Future<MilestoneModel> createMilestone(MilestoneModel m) async {
    final ref = await _db.collection('milestones').add(m.toFirestore());
    final doc = await ref.get();
    return MilestoneModel.fromFirestore(doc);
  }

  Future<void> updateMilestone(MilestoneModel m) =>
      _db.collection('milestones').doc(m.id).update(m.toFirestore());
  Future<void> deleteMilestone(String id) =>
      _db.collection('milestones').doc(id).delete();
  Future<void> completeMilestone(String id) =>
      _db.collection('milestones').doc(id).update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
  Stream<List<SessionModel>> sessionsStream(String thesisId) => _db
          .collection('sessions')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(SessionModel.fromFirestore).toList();
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return list;
      });
  Stream<List<SessionModel>> allSessionsStream(String userId) => _db
          .collection('sessions')
          .where('studentId', isEqualTo: userId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(SessionModel.fromFirestore).toList();
        list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return list;
      });
  Future<SessionModel> createSession(SessionModel session) async {
    final ref = await _db.collection('sessions').add(session.toFirestore());
    final doc = await ref.get();
    return SessionModel.fromFirestore(doc);
  }

  Future<void> updateSession(SessionModel session) =>
      _db.collection('sessions').doc(session.id).update(session.toFirestore());
  Future<void> deleteSession(String id) =>
      _db.collection('sessions').doc(id).delete();
  Stream<List<NoteModel>> notesStream(String thesisId) => _db
          .collection('notes')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(NoteModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
  Future<void> createNote(NoteModel note) =>
      _db.collection('notes').add(note.toFirestore());
  Future<void> updateNote(NoteModel note) =>
      _db.collection('notes').doc(note.id).update(note.toFirestore());
  Future<void> deleteNote(String id) =>
      _db.collection('notes').doc(id).delete();
  Stream<List<AttachmentModel>> attachmentsStream(String thesisId) => _db
          .collection('attachments')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(AttachmentModel.fromFirestore).toList();
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        return list;
      });
  Future<void> createAttachment(AttachmentModel a) =>
      _db.collection('attachments').add(a.toFirestore());
  Future<void> deleteAttachment(String id) =>
      _db.collection('attachments').doc(id).delete();
  Stream<List<AttachmentModel>> thesisLinksStream(String thesisId) => _db
          .collection('attachments')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs
            .map(AttachmentModel.fromFirestore)
            .where((a) => a.bimbinganId == null)
            .toList();
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        return list;
      });
  Stream<List<BimbinganModel>> bimbinganStream(String thesisId) => _db
          .collection('bimbingan')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(BimbinganModel.fromFirestore).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });
  Future<void> createBimbingan(BimbinganModel b) =>
      _db.collection('bimbingan').add(b.toFirestore());
  Future<void> updateBimbingan(BimbinganModel b) =>
      _db.collection('bimbingan').doc(b.id).update(b.toFirestore());
  Future<void> deleteBimbingan(String id) =>
      _db.collection('bimbingan').doc(id).delete();
  Stream<List<NoteModel>> notesForBimbingan(String bimbinganId) => _db
          .collection('notes')
          .where('bimbinganId', isEqualTo: bimbinganId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(NoteModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
  Stream<List<AttachmentModel>> attachmentsForBimbingan(String bimbinganId) =>
      _db
          .collection('attachments')
          .where('bimbinganId', isEqualTo: bimbinganId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(AttachmentModel.fromFirestore).toList();
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        return list;
      });
}
