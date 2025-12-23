import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:assist/auth/login_screen.dart';
import 'package:assist/auth/role_selection_screen.dart';
import 'package:assist/common/contact_us_page.dart';
import 'package:assist/common/faq_page.dart';
import 'package:assist/common/privacy_policy_page.dart';
import 'package:assist/common/profile_page.dart';
import 'package:assist/common/messages_page.dart';
import 'package:assist/common/settings_screen.dart';
import 'package:assist/common/terms_and_conditions_page.dart';
import 'package:assist/controllers/current_user_controller.dart';
import 'package:assist/models/app_user.dart';
import 'package:assist/services/user_service.dart';
import 'package:assist/user/my_bookings_page.dart';
import 'package:assist/user/main_page.dart';
import 'package:assist/user/customer_categories_page.dart';
import 'package:assist/user/customer_shell_page.dart';
import 'package:assist/worker/worker_earnings_page.dart';
import 'package:assist/worker/worker_home_screen.dart';
import 'package:assist/worker/worker_jobs_page.dart';
import 'package:assist/worker/worker_shell_page.dart';
import 'package:assist/admin/admin_analytics_page.dart';
import 'package:assist/admin/admin_notifications_page.dart';
import 'package:assist/admin/admin_shell_page.dart';
import 'package:assist/admin/admin_workers_page.dart';

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

      final bool isCustomerArea =
          location == '/home' ||
          location.startsWith('/home/') ||
          location == '/categories' ||
          location.startsWith('/categories/') ||
          location == '/bookings' ||
          location.startsWith('/bookings/') ||
          location == '/messages' ||
          location.startsWith('/messages/') ||
          location == '/profile' ||
          location.startsWith('/profile/');

      if (isCustomerArea && currentProfile.role != UserRole.customer) {
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'customerHome',
                builder: (context, state) => const MainPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                name: 'customerCategories',
                builder: (context, state) => const CustomerCategoriesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                name: 'customerBookings',
                builder: (context, state) => const MyBookingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                name: 'customerMessages',
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'customerProfile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return WorkerShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/worker',
                name: 'workerHome',
                builder: (context, state) => const WorkerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/worker/jobs',
                name: 'workerJobs',
                builder: (context, state) => const WorkerJobsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/worker/earnings',
                name: 'workerEarnings',
                builder: (context, state) => const WorkerEarningsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/worker/messages',
                name: 'workerMessages',
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/worker/profile',
                name: 'workerProfile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                name: 'adminHome',
                builder: (context, state) => const AdminAnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/workers',
                name: 'adminWorkers',
                builder: (context, state) => const AdminWorkersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/notifications',
                name: 'adminNotifications',
                builder: (context, state) => const AdminNotificationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                name: 'adminProfile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
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

  String? _locationAttemptedForUserId;

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
    _locationAttemptedForUserId = null;

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
        _maybeEnsureUserLocationAndAddress(value);
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

  void _maybeEnsureUserLocationAndAddress(AppUser? nextProfile) {
    final current = user;
    if (current == null) return;
    if (nextProfile == null) return;
    if (!nextProfile.hasRole) return;

    if (_locationAttemptedForUserId == current.uid) return;
    _locationAttemptedForUserId = current.uid;

    Future.microtask(() => _ensureUserLocationAndAddress(nextProfile));
  }
}

Future<void> _ensureUserLocationAndAddress(AppUser profile) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    if (profile.locationLat != null &&
        profile.locationLng != null &&
        profile.city != null &&
        profile.town != null) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    String? city;
    String? town;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
        town = p.subLocality ?? p.locality;

        final lowerCity = city?.toLowerCase() ?? '';
        if (lowerCity.contains('lahore')) {
          city = 'Lahore';
        } else if (lowerCity.contains('islamabad')) {
          city = 'Islamabad';
        } else if (lowerCity.contains('karachi')) {
          city = 'Karachi';
        }
      }
    } catch (_) {
      // Ignore reverse geocoding errors; location is still useful.
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

    if (update.isNotEmpty) {
      await UserService.instance.updateUser(profile.id, update);
    }
  } catch (_) {
    // Silently ignore failures for auto location.
  }
}
