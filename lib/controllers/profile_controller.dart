import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/media_permission_service.dart';
import '../services/user_service.dart';
import '../common/ui_helpers.dart';

class ProfileLocationResult {
  final String? city;
  final String? town;
  final String? addressLine1;

  const ProfileLocationResult({
    this.city,
    this.town,
    this.addressLine1,
  });
}

class ProfileController {
  const ProfileController._();

  /// Change the user's profile image by picking from gallery and uploading.
  static Future<void> changeProfileImage(
    BuildContext context,
    String uid,
  ) async {
    bool dialogShown = false;

    try {
      final hasPermission =
          await MediaPermissionService.ensurePhotosPermission();
      if (!context.mounted) return;
      if (!hasPermission) {
        UIHelpers.showSnack(
          context,
          'Please allow photo access to change your profile picture.',
        );
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final fileName = picked.name;

      if (!context.mounted) return;
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uploadResult = await UserService.instance.uploadProfileImage(
        uid,
        bytes,
        fileName,
      );
      await UserService.instance
          .updateProfileImageUrl(uid, uploadResult.secureUrl);
      await UserService.instance.updateUser(uid, {
        'profileImagePublicId': uploadResult.publicId,
      });

      if (!context.mounted) return;
      if (dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      UIHelpers.showSnack(context, 'Profile picture updated.');
    } catch (e) {
      if (!context.mounted) return;
      if (dialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      UIHelpers.showSnack(
        context,
        'Could not update profile picture: $e',
      );
    }
  }

  /// Start phone verification flow for the given profile.
  static Future<void> startPhoneVerification(
    BuildContext context,
    AppUser profile,
  ) async {
    final phone = profile.phone?.trim();

    if (phone == null || phone.isEmpty) {
      UIHelpers.showSnack(
        context,
        'Please add your phone number in Edit profile first.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      UIHelpers.showSnack(context, 'You must be logged in to verify.');
      return;
    }

    // If phone provider is already linked, just mark verified.
    final alreadyLinked =
        user.providerData.any((p) => p.providerId == 'phone');
    if (alreadyLinked) {
      await UserService.instance.updateUser(profile.id, {'verified': true});
      if (!context.mounted) return;
      UIHelpers.showSnack(context, 'Phone already verified.');
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!context.mounted) return;
          try {
            await user.linkWithCredential(credential);
          } catch (_) {
            // Ignore link errors; user might already be linked.
          }

          await UserService.instance
              .updateUser(profile.id, {'verified': true});

          if (!context.mounted) return;
          // Simple analytics/logging
          // ignore: avoid_print
          print('PHONE_VERIFIED_AUTO uid=${profile.id}');
          UIHelpers.showSnack(context, 'Phone verified successfully.');
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!context.mounted) return;
          UIHelpers.showSnack(
            context,
            'Verification failed: ${e.message}',
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          if (!context.mounted) return;
          await _showOtpBottomSheet(
            context: context,
            verificationId: verificationId,
            profile: profile,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Optional: you can inform the user that auto-retrieval timed out.
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showSnack(
        context,
        'Could not start phone verification: $e',
      );
    }
  }

  static Future<void> _showOtpBottomSheet({
    required BuildContext context,
    required String verificationId,
    required AppUser profile,
  }) async {
    final codeController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: bottomInset + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'We\'ve sent a 6-digit code to your phone. Enter it below to verify your account.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP code',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!context.mounted) return;
                    final code = codeController.text.trim();
                    if (code.length < 6) {
                      UIHelpers.showSnack(
                        context,
                        'Please enter the 6-digit code.',
                      );
                      return;
                    }

                    try {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: code,
                      );

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        UIHelpers.showSnack(
                          context,
                          'You must be logged in to verify.',
                        );
                        return;
                      }

                      try {
                        await user.linkWithCredential(credential);
                      } catch (_) {
                        // Ignore link errors; user might already be linked or signed in.
                      }

                      await UserService.instance
                          .updateUser(profile.id, {'verified': true});

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      // ignore: avoid_print
                      print('PHONE_VERIFIED_OTP uid=${profile.id}');
                      UIHelpers.showSnack(
                        context,
                        'Phone verified successfully.',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      UIHelpers.showSnack(context, 'Invalid code: $e');
                    }
                  },
                  child: const Text('Verify'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Use the device's current location to update the user's stored address
  /// and return the resolved city/town/address for populating the UI.
  static Future<ProfileLocationResult?> updateLocationFromCurrentPosition(
    BuildContext context,
    String userId,
  ) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!context.mounted) return null;
      if (!serviceEnabled) {
        UIHelpers.showSnack(
          context,
          'Please enable location services to use this feature.',
        );
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (!context.mounted) return null;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!context.mounted) return null;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        UIHelpers.showSnack(
          context,
          'Location permission denied. Please enable it in settings.',
        );
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Debug: log raw coordinates
      // ignore: avoid_print
      print('LOCATION_POSITION lat=${position.latitude}, lng=${position.longitude}');

      String? city;
      String? town;
      String? addressLine1;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
          town = p.subLocality ?? p.locality;

          addressLine1 = p.street;
          if (addressLine1 == null || addressLine1.trim().isEmpty) {
            addressLine1 = p.name;
          }

          // Debug: log resolved place components
          // ignore: avoid_print
          print(
            'LOCATION_PLACE city=' '${city ?? 'null'}' ', '
            'town=' '${town ?? 'null'}' ', '
            'addressLine1=' '${addressLine1 ?? 'null'}',
          );

          final lowerCity = city?.toLowerCase() ?? '';
          if (lowerCity.contains('lahore')) {
            city = 'Lahore';
          } else if (lowerCity.contains('islamabad')) {
            city = 'Islamabad';
          } else if (lowerCity.contains('karachi')) {
            city = 'Karachi';
          }
          // Debug: log resolved place components
          // ignore: avoid_print
          print(
            'LOCATION_PLACE city=' '${city ?? 'null'}' ', '
            'town=' '${town ?? 'null'}' ', '
            'addressLine1=' '${addressLine1 ?? 'null'}',
          );
        }
      } catch (_) {
        // Ignore reverse geocoding failures; still save raw location.
        // ignore: avoid_print
        print('LOCATION_GEOCODE_FAILED for lat=${position.latitude}, lng=${position.longitude}');
      }

      final update = <String, dynamic>{
        'locationLat': position.latitude,
        'locationLng': position.longitude,
      };

      if (city != null && city.isNotEmpty) {
        update['city'] = city;
      }

      if (town != null && town.isNotEmpty) {
        update['town'] = town;
      }

      if (addressLine1 != null && addressLine1.trim().isNotEmpty) {
        update['addressLine1'] = addressLine1;
      }

      await UserService.instance.updateUser(userId, update);

      if (!context.mounted) return null;
      UIHelpers.showSnack(
        context,
        'Location and city/town updated from your current position.',
      );

      return ProfileLocationResult(
        city: city,
        town: town,
        addressLine1: addressLine1,
      );
    } catch (e) {
      if (!context.mounted) return null;
      UIHelpers.showSnack(context, 'Could not fetch location: $e');
      return null;
    }
  }

  /// Delete the current Firebase user and their user document.
  /// NOTE: This does not cascade delete related data (bookings, etc.).
  static Future<void> deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text(
            'This will permanently delete your account and data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      UIHelpers.showSnack(context, 'You must be logged in to delete account.');
      return;
    }

    try {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      await user.delete();

      if (!context.mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        UIHelpers.showSnack(
          context,
          'Please log in again and then try deleting your account.',
        );
      } else {
        UIHelpers.showSnack(
          context,
          'Could not delete account: ${e.code}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        UIHelpers.showSnack(context, 'Could not delete account: $e');
      }
    }
  }
}
