import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'cloudinary_service.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, AppUser> _userCache = <String, AppUser>{};

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users');

  Future<AppUser?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final user = AppUser.fromMap(doc.id, doc.data()!);
    _userCache[id] = user;
    return user;
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) {
    return _col.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> addToWallet(String id, num amount) {
    return _col.doc(id).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }

  Future<CloudinaryUploadResult> uploadProfileImage(
      String uid, Uint8List bytes, String fileName) async {
    final uniquePublicId = '${uid}_${DateTime.now().millisecondsSinceEpoch}';
    final result = await CloudinaryService.instance.uploadImage(
      bytes: bytes,
      folder: 'user_profile_images',
      publicId: uniquePublicId,
      fileName: fileName,
    );
    return result;
  }

  Future<void> updateProfileImageUrl(String uid, String url) {
    return updateUser(uid, {'profileImageUrl': url});
  }

  Stream<AppUser?> watchUser(String id) {
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      final user = AppUser.fromMap(snap.id, snap.data()!);
      _userCache[id] = user;
      return user;
    });
  }

  /// Batch-load many users by ID with a small number of whereIn queries,
  /// reusing an in-memory cache to avoid repeated reads.
  Future<Map<String, AppUser?>> getUsersBatch(List<String> ids) async {
    final result = <String, AppUser?>{};
    if (ids.isEmpty) return result;

    final missing = <String>[];
    for (final id in ids) {
      final cached = _userCache[id];
      if (cached != null) {
        result[id] = cached;
      } else {
        missing.add(id);
      }
    }

    if (missing.isEmpty) return result;

    const chunkSize = 10;
    for (var i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.sublist(i, min(i + chunkSize, missing.length));
      final snap = await _col
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final user = AppUser.fromMap(doc.id, doc.data());
        _userCache[doc.id] = user;
        result[doc.id] = user;
      }
    }

    for (final id in missing) {
      result.putIfAbsent(id, () => null);
    }

    return result;
  }
}
