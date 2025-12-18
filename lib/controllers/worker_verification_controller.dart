import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/common/ui_helpers.dart';
import 'package:flutter_application_1/services/ai_backend_service.dart';
import 'package:flutter_application_1/services/cloudinary_service.dart';
import 'package:flutter_application_1/services/media_permission_service.dart';
import 'package:flutter_application_1/services/user_service.dart';

class WorkerVerificationController {
  const WorkerVerificationController._();

  static final Map<String, Uint8List> _recentUploadBytes =
      <String, Uint8List>{};

  static final Map<String, DateTime> _lastAutoRunAtByUid =
      <String, DateTime>{};

  static Future<void> ensureAiVerificationForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _runAiVerification(user.uid);
    } catch (e) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          <String, dynamic>{
            'verification': <String, dynamic>{
              'lastError': e.toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  static Future<String?> getIdTokenForDebug({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  static Future<void> maybeRunAiVerificationForCurrentUser({
    Duration minInterval = const Duration(minutes: 2),
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final lastRunAt = _lastAutoRunAtByUid[user.uid];
    if (lastRunAt != null && DateTime.now().difference(lastRunAt) < minInterval) {
      return;
    }

    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      final String? cnicFrontUrl = data['cnicFrontImageUrl'] as String?;
      final String? cnicBackUrl = data['cnicBackImageUrl'] as String?;
      final String? selfieUrl = data['selfieImageUrl'] as String?;
      final String? shopUrl = data['shopImageUrl'] as String?;

      final Map<String, dynamic>? verification =
          data['verification'] as Map<String, dynamic>?;
      final Timestamp? verificationUpdatedAt =
          verification?['updatedAt'] as Timestamp?;
      final Map<String, dynamic>? verificationInputs =
          verification?['inputs'] as Map<String, dynamic>?;

      final bool hasAnyImage =
          cnicFrontUrl != null || cnicBackUrl != null || selfieUrl != null || shopUrl != null;
      if (!hasAnyImage) return;

      bool inputsChanged() {
        if (verificationInputs == null) return true;
        if ((verificationInputs['cnicFrontImageUrl'] as String?) != cnicFrontUrl) {
          return true;
        }
        if ((verificationInputs['cnicBackImageUrl'] as String?) != cnicBackUrl) {
          return true;
        }
        if ((verificationInputs['selfieImageUrl'] as String?) != selfieUrl) {
          return true;
        }
        if ((verificationInputs['shopImageUrl'] as String?) != shopUrl) {
          return true;
        }
        return false;
      }

      final bool missingCnicResult = cnicFrontUrl != null &&
          cnicBackUrl != null &&
          verification?['cnic'] == null;
      final bool missingFaceResult = cnicFrontUrl != null &&
          selfieUrl != null &&
          verification?['face'] == null;
      final bool missingShopResult =
          shopUrl != null && verification?['shop'] == null;

      final bool shouldRunAi =
          verificationUpdatedAt == null || inputsChanged() || missingCnicResult || missingFaceResult || missingShopResult;
      if (!shouldRunAi) return;

      _lastAutoRunAtByUid[user.uid] = DateTime.now();
      await _runAiVerification(user.uid);
    } catch (e) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          <String, dynamic>{
            'verification': <String, dynamic>{
              'lastError': e.toString(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  /// Pick an image for the given verification [field], upload it,
  /// update Firestore, and return the new URL.
  ///
  /// Returns `null` if the user cancels, is not logged in, or an
  /// error occurs (an error SnackBar will already be shown).
  static Future<String?> pickAndUpload(
    BuildContext context,
    String field,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      UIHelpers.showSnack(context, 'You must be logged in to verify.');
      return null;
    }

    bool dialogShown = false;

    try {
      final hasPermission =
          await MediaPermissionService.ensureCameraPermission();
      if (!context.mounted) return null;
      if (!hasPermission) {
        UIHelpers.showSnack(
          context,
          'Camera permission is required to take verification photos.',
        );
        return null;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      final fileName = picked.name;

      _recentUploadBytes['${user.uid}_$field'] = bytes;

      if (!context.mounted) return null;
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uniquePublicId = '${field}_${DateTime.now().microsecondsSinceEpoch}';

      // Upload via Cloudinary and store URL/publicId in the corresponding user fields.
      final result = await CloudinaryService.instance.uploadImage(
        bytes: bytes,
        folder: 'worker_verification/${user.uid}',
        publicId: uniquePublicId,
        fileName: fileName,
      );
      final url = result.secureUrl;

      final Map<String, dynamic> updateData = {
        field: url,
        '${field}PublicId': result.publicId,
        'verificationStatus': 'pending',
      };

      switch (field) {
        case 'cnicFrontImageUrl':
          updateData['cnicFrontStatus'] = 'pending';
          break;
        case 'cnicBackImageUrl':
          updateData['cnicBackStatus'] = 'pending';
          break;
        case 'selfieImageUrl':
          updateData['selfieStatus'] = 'pending';
          break;
        case 'shopImageUrl':
          updateData['shopStatus'] = 'pending';
          break;
      }

      await UserService.instance.updateUser(user.uid, updateData);

      try {
        await _runAiVerification(user.uid);
      } catch (e) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            <String, dynamic>{
              'verification': <String, dynamic>{
                'lastError': e.toString(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            },
            SetOptions(merge: true),
          );
        } catch (_) {}
      }

      if (!context.mounted) return null;
      if (dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      UIHelpers.showSnack(context, 'Image uploaded successfully.');

      return url;
    } catch (e) {
      if (!context.mounted) return null;
      if (dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      UIHelpers.showSnack(context, 'Could not upload image: $e');
      return null;
    }
  }

  /// Submit verification by marking all document statuses as pending
  /// and setting the overall verificationStatus.
  ///
  /// Returns `true` if the submission succeeded, otherwise `false`.
  static Future<bool> submitVerification(
    BuildContext context, {
    required String? cnicFrontUrl,
    required String? cnicBackUrl,
    required String? selfieUrl,
    required String? shopUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        UIHelpers.showSnack(context, 'You must be logged in to verify.');
      }
      return false;
    }

    if (cnicFrontUrl == null ||
        cnicBackUrl == null ||
        selfieUrl == null ||
        shopUrl == null) {
      UIHelpers.showSnack(
        context,
        'Please upload CNIC front & back pictures, live picture, and shop/tools pictures first.',
      );
      return false;
    }

    try {
      // Trigger smart CNIC analysis on the backend so admins can see
      // extracted details in their panel. This runs before we mark the
      // verification as pending but does not block submission if it fails.
      try {
        final currentUser = await UserService.instance.getById(user.uid);
        final frontBytes =
            _recentUploadBytes['${user.uid}_cnicFrontImageUrl'];
        final backBytes = _recentUploadBytes['${user.uid}_cnicBackImageUrl'];
        final selfieBytes = _recentUploadBytes['${user.uid}_selfieImageUrl'];
        final shopBytes = _recentUploadBytes['${user.uid}_shopImageUrl'];

        final cnic = (frontBytes != null && backBytes != null)
            ? await AiBackendService.instance.verifyCnicFromBytes(
                cnicFrontBytes: frontBytes,
                cnicBackBytes: backBytes,
                expectedName: currentUser?.name,
              )
            : await AiBackendService.instance.verifyCnic(
                cnicFrontUrl: cnicFrontUrl,
                cnicBackUrl: cnicBackUrl,
                expectedName: currentUser?.name,
              );

        final face = (frontBytes != null && selfieBytes != null)
            ? await AiBackendService.instance.verifyFaceFromBytes(
                cnicImageBytes: frontBytes,
                selfieImageBytes: selfieBytes,
              )
            : await AiBackendService.instance.verifyFace(
                cnicImageUrl: cnicFrontUrl,
                selfieImageUrl: selfieUrl,
              );

        final shop = (shopBytes != null)
            ? await AiBackendService.instance.verifyShopFromBytes(
                shopImageBytes: shopBytes,
              )
            : await AiBackendService.instance.verifyShop(shopImageUrl: shopUrl);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          <String, dynamic>{
            'verification': <String, dynamic>{
              'cnic': cnic,
              'face': face,
              'shop': shop,
              'inputs': <String, dynamic>{
                'cnicFrontImageUrl': cnicFrontUrl,
                'cnicBackImageUrl': cnicBackUrl,
                'selfieImageUrl': selfieUrl,
                'shopImageUrl': shopUrl,
              },
              'lastError': null,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            <String, dynamic>{
              'verification': <String, dynamic>{
                'lastError': e.toString(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            },
            SetOptions(merge: true),
          );
        } catch (_) {}
        // Ignore AI errors here; the manual verification flow should
        // continue even if automatic CNIC parsing fails.
      }

      await UserService.instance.updateUser(user.uid, {
        'verificationStatus': 'pending',
        'cnicFrontStatus': 'pending',
        'cnicBackStatus': 'pending',
        'selfieStatus': 'pending',
        'shopStatus': 'pending',
      });

      if (!context.mounted) return false;
      UIHelpers.showSnack(
        context,
        'Verification details submitted. Your account is under review.',
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      UIHelpers.showSnack(context, 'Could not submit verification: $e');
      return false;
    }
  }

  static Future<void> _runAiVerification(String uid) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;

    final String? cnicFrontUrl = data['cnicFrontImageUrl'] as String?;
    final String? cnicBackUrl = data['cnicBackImageUrl'] as String?;
    final String? selfieUrl = data['selfieImageUrl'] as String?;
    final String? shopUrl = data['shopImageUrl'] as String?;

    final updates = <String, dynamic>{
      'verification': <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'inputs': <String, dynamic>{
          'cnicFrontImageUrl': cnicFrontUrl,
          'cnicBackImageUrl': cnicBackUrl,
          'selfieImageUrl': selfieUrl,
          'shopImageUrl': shopUrl,
        },
      },
    };

    var didAny = false;

    if (cnicFrontUrl != null && cnicBackUrl != null) {
      try {
        final frontBytes = _recentUploadBytes['${uid}_cnicFrontImageUrl'];
        final backBytes = _recentUploadBytes['${uid}_cnicBackImageUrl'];

        final cnic = (frontBytes != null && backBytes != null)
            ? await AiBackendService.instance.verifyCnicFromBytes(
                cnicFrontBytes: frontBytes,
                cnicBackBytes: backBytes,
                expectedName: data['name'] as String?,
              )
            : await AiBackendService.instance.verifyCnic(
                cnicFrontUrl: cnicFrontUrl,
                cnicBackUrl: cnicBackUrl,
                expectedName: data['name'] as String?,
              );
        (updates['verification'] as Map<String, dynamic>)['cnic'] = cnic;
        (updates['verification'] as Map<String, dynamic>)['cnicError'] = null;
        didAny = true;
      } catch (e) {
        (updates['verification'] as Map<String, dynamic>)['cnicError'] =
            e.toString();
        didAny = true;
      }
    }

    if (cnicFrontUrl != null && selfieUrl != null) {
      try {
        final frontBytes = _recentUploadBytes['${uid}_cnicFrontImageUrl'];
        final selfieBytes = _recentUploadBytes['${uid}_selfieImageUrl'];

        final face = (frontBytes != null && selfieBytes != null)
            ? await AiBackendService.instance.verifyFaceFromBytes(
                cnicImageBytes: frontBytes,
                selfieImageBytes: selfieBytes,
              )
            : await AiBackendService.instance.verifyFace(
                cnicImageUrl: cnicFrontUrl,
                selfieImageUrl: selfieUrl,
              );
        (updates['verification'] as Map<String, dynamic>)['face'] = face;
        (updates['verification'] as Map<String, dynamic>)['faceError'] = null;
        didAny = true;
      } catch (e) {
        (updates['verification'] as Map<String, dynamic>)['faceError'] =
            e.toString();
        didAny = true;
      }
    }

    if (shopUrl != null) {
      try {
        final shopBytes = _recentUploadBytes['${uid}_shopImageUrl'];

        final shop = (shopBytes != null)
            ? await AiBackendService.instance.verifyShopFromBytes(
                shopImageBytes: shopBytes,
              )
            : await AiBackendService.instance.verifyShop(shopImageUrl: shopUrl);
        (updates['verification'] as Map<String, dynamic>)['shop'] = shop;
        (updates['verification'] as Map<String, dynamic>)['shopError'] = null;
        didAny = true;
      } catch (e) {
        (updates['verification'] as Map<String, dynamic>)['shopError'] =
            e.toString();
        didAny = true;
      }
    }

    final verificationUpdate = updates['verification'] as Map<String, dynamic>;
    final String? cnicError = verificationUpdate['cnicError'] as String?;
    final String? faceError = verificationUpdate['faceError'] as String?;
    final String? shopError = verificationUpdate['shopError'] as String?;
    final errors = <String>[
      if (cnicError != null && cnicError.trim().isNotEmpty) cnicError,
      if (faceError != null && faceError.trim().isNotEmpty) faceError,
      if (shopError != null && shopError.trim().isNotEmpty) shopError,
    ];
    verificationUpdate['lastError'] = errors.isEmpty ? null : errors.join('\n');

    if (!didAny) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
          updates,
          SetOptions(merge: true),
        );
  }
}
