import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/user_service.dart';

class CurrentUserController {
  const CurrentUserController._();

  static Stream<AppUser?>? _currentUserStream;

  /// Watch the currently logged-in user's profile from Firestore.
  ///
  /// This subscribes to the underlying user document only once and shares
  /// the stream across all listeners to avoid duplicate Firestore listeners.
  static Stream<AppUser?> watchCurrentUser() {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      return Stream<AppUser?>.value(null);
    }

    _currentUserStream ??=
        UserService.instance.watchUser(current.uid).asBroadcastStream();
    return _currentUserStream!;
  }

  /// Reset the cached stream, e.g. after logout.
  static void reset() {
    _currentUserStream = null;
  }
}
