import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_model.dart';
import 'cloudinary_service.dart';

class MediaService {
  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();
  Future<XFile?> capturePhoto() => _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
  Future<XFile?> captureVideo() => _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
  Future<String> uploadFile(String filePath) =>
      CloudinaryService.upload(filePath);
  Future<void> saveMedia(MediaModel media) =>
      _db.collection('media').doc(media.id).set(media.toFirestore());
  Stream<List<MediaModel>> mediaStream(String thesisId) => _db
          .collection('media')
          .where('thesisId', isEqualTo: thesisId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(MediaModel.fromFirestore).toList();
        list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
        return list;
      });
  Stream<List<MediaModel>> mediaForBimbingan(String bimbinganId) => _db
          .collection('media')
          .where('bimbinganId', isEqualTo: bimbinganId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(MediaModel.fromFirestore).toList();
        list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
        return list;
      });
  Future<void> deleteMedia(MediaModel media) =>
      _db.collection('media').doc(media.id).delete();
}
