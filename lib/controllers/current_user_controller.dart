import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:assist/models/app_user.dart';
import 'package:assist/services/user_service.dart';

class CurrentUserController {
  const CurrentUserController._();

  static String? _currentUserId;
  static StreamController<AppUser?>? _controller;
  static StreamSubscription<AppUser?>? _sub;
  static AppUser? _lastValue;
  static bool _hasValue = false;

  /// Watch the currently logged-in user's profile from Firestore.
  ///
  /// This subscribes to the underlying user document only once and shares
  /// the stream across all listeners to avoid duplicate Firestore listeners.
  static Stream<AppUser?> watchCurrentUser() {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      reset();
      return Stream<AppUser?>.value(null);
    }

    if (_currentUserId != current.uid || _controller == null || _sub == null) {
      _currentUserId = current.uid;
      _sub?.cancel();
      _controller?.close();
      _controller = StreamController<AppUser?>.broadcast();
      _lastValue = null;
      _hasValue = false;
      _sub = UserService.instance
          .watchUser(current.uid)
          .listen(
            (value) {
              _lastValue = value;
              _hasValue = true;
              _controller?.add(value);
            },
            onError: (Object e, StackTrace st) {
              _controller?.addError(e, st);
            },
          );
    }

    final controller = _controller;
    if (controller == null) {
      return Stream<AppUser?>.value(null);
    }

    return Stream<AppUser?>.multi((multi) {
      if (_hasValue) {
        multi.add(_lastValue);
      }

      final sub = controller.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );

      multi.onCancel = () {
        sub.cancel();
      };
    });
  }

  /// Reset the cached stream, e.g. after logout.
  static void reset() {
    _currentUserId = null;
    _lastValue = null;
    _hasValue = false;
    _sub?.cancel();
    _sub = null;
    _controller?.close();
    _controller = null;
  }
}
