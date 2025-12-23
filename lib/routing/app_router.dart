import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:assist/auth/login_screen.dart';
import 'package:assist/auth/role_selection_screen.dart';
import 'package:assist/common/contact_us_page.dart';
import 'package:assist/common/faq_page.dart';
import 'package:assist/common/privacy_policy_page.dart';
import 'package:assist/common/profile_page.dart';
import 'package:assist/common/role_home_page.dart';
import 'package:assist/common/settings_screen.dart';
import 'package:assist/common/terms_and_conditions_page.dart';
import 'package:assist/controllers/current_user_controller.dart';
import 'package:assist/models/app_user.dart';
import 'package:assist/services/user_service.dart';
import 'package:assist/user/my_bookings_page.dart';

class AppRouter {
  AppRouter._();

  static final _session = _RouterSession();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _session,
    redirect: (context, state) {
      final String location = state.uri.path;

      final bool isAuthRoute = location == '/auth';
      final bool isRoleRoute = location == '/role';
      final bool isSplashRoute = location == '/';

      final bool isInfoRoute = location == '/faq' ||
          location == '/contact' ||
          location == '/terms' ||
          location == '/privacy';

      final bool isPublicRoute = isAuthRoute || isInfoRoute;

      final user = _session.user;
      final profile = _session.profile;

      final bool isLoggedIn = user != null;

      if (!isLoggedIn) {
        if (isSplashRoute) return '/auth';
        if (isPublicRoute) return null;
        return '/auth';
      }

      if (!_session.profileLoaded) {
        if (isSplashRoute) return null;
        return '/';
      }

      final p = profile;
      final bool hasRole = p != null && p.hasRole;

      if (!hasRole) {
        if (isRoleRoute) return null;
        if (isInfoRoute) return null;
        return '/role';
      }

      final AppUser currentProfile = p;

      final String homeForRole = switch (currentProfile.role) {
        UserRole.customer => '/home',
        UserRole.provider => '/worker',
        UserRole.admin => '/admin',
      };

      if (isSplashRoute || isAuthRoute || isRoleRoute) {
        return homeForRole;
      }

      if (location.startsWith('/admin') &&
          currentProfile.role != UserRole.admin) {
        return homeForRole;
      }

      if (location.startsWith('/worker') &&
          currentProfile.role != UserRole.provider) {
        return homeForRole;
      }

      if (location == '/home' && currentProfile.role != UserRole.customer) {
        return homeForRole;
      }

      if (location == '/bookings' &&
          currentProfile.role != UserRole.customer) {
        return homeForRole;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const _BootstrapPage(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/role',
        name: 'role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const RoleHomePage(),
      ),
      GoRoute(
        path: '/worker',
        name: 'workerHome',
        builder: (context, state) => const RoleHomePage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'adminHome',
        builder: (context, state) => const RoleHomePage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const MyBookingsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FaqPage(),
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
    ],
  );
}

class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RouterSession extends ChangeNotifier {
  User? user;
  AppUser? profile;
  bool profileLoaded = false;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;
  Timer? _profileTimeout;

  _RouterSession() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  void _onAuthChanged(User? next) {
    user = next;
    profile = null;
    profileLoaded = false;

    _profileSub?.cancel();
    _profileSub = null;

    _profileTimeout?.cancel();
    _profileTimeout = null;

    if (next == null) {
      CurrentUserController.reset();
      notifyListeners();
      return;
    }

    // Avoid infinite loading at '/' if the profile stream never emits (e.g.
    // slow network or Firestore permission issues). We fail open into the
    // role selection flow so the user isn't stuck.
    _profileTimeout = Timer(const Duration(seconds: 6), () {
      if (profileLoaded) return;
      profileLoaded = true;
      notifyListeners();
    });

    _profileSub = UserService.instance.watchUser(next.uid).listen(
      (value) {
        profile = value;
        profileLoaded = true;
        _profileTimeout?.cancel();
        _profileTimeout = null;
        notifyListeners();
      },
      onError: (Object _, StackTrace stackTrace) {
        profileLoaded = true;
        _profileTimeout?.cancel();
        _profileTimeout = null;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _profileTimeout?.cancel();
    super.dispose();
  }
}
