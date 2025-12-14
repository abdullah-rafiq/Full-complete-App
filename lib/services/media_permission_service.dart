import 'package:permission_handler/permission_handler.dart';

/// Simple helper for handling runtime permissions related to media and camera.
class MediaPermissionService {
  const MediaPermissionService._();

  /// Request permission to access photos / media library.
  ///
  /// Returns `true` if permission is granted (or limited on iOS),
  /// otherwise `false`.
  static Future<bool> ensurePhotosPermission() async {
    var status = await Permission.photos.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    return false;
  }

  /// Request permission to use the camera.
  ///
  /// Returns `true` if permission is granted, otherwise `false`.
  static Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
