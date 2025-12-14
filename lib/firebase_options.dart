import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_API_KEY_WEB'),
        appId: const String.fromEnvironment('FIREBASE_APP_ID_WEB'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_WEB'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID_WEB'),
        authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN_WEB'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET_WEB'),
        measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID_WEB'),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_API_KEY_ANDROID'),
          appId: const String.fromEnvironment('FIREBASE_APP_ID_ANDROID'),
          messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_ANDROID'),
          projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID_ANDROID'),
          storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET_ANDROID'),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_API_KEY_IOS'),
          appId: const String.fromEnvironment('FIREBASE_APP_ID_IOS'),
          messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_IOS'),
          projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID_IOS'),
          storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET_IOS'),
        );
      case TargetPlatform.windows:
        return FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_API_KEY_WINDOWS'),
          appId: const String.fromEnvironment('FIREBASE_APP_ID_WINDOWS'),
          messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_WINDOWS'),
          projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID_WINDOWS'),
          authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN_WINDOWS'),
          storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET_WINDOWS'),
          measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID_WINDOWS'),
        );
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not configured.');
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }
}
