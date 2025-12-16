import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/common/ui_helpers.dart';
import 'package:flutter_application_1/services/ai_backend_service.dart';
import 'package:flutter_application_1/services/cloudinary_service.dart';
import 'package:flutter_application_1/services/media_permission_service.dart';
import 'package:flutter_application_1/services/user_service.dart';

class WorkerVerificationController {
  const WorkerVerificationController._();

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
      final hasPermission = await MediaPermissionService.ensureCameraPermission();
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

      if (!context.mounted) return null;
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Upload via Cloudinary and store URL/publicId in the corresponding user fields.
      final result = await CloudinaryService.instance.uploadImage(
        bytes: bytes,
        folder: 'worker_verification/${user.uid}',
        publicId: field,
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
        await AiBackendService.instance.verifyCnic(
          cnicFrontUrl: cnicFrontUrl,
          cnicBackUrl: cnicBackUrl,
          expectedName: currentUser?.name,
        );
      } catch (_) {
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
}
