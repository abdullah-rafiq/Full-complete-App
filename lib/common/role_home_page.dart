import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/controllers/current_user_controller.dart';
import 'package:flutter_application_1/user/main_page.dart' deferred as user_main;
import 'package:flutter_application_1/worker/worker_main_page.dart' deferred as worker_main;
import 'package:flutter_application_1/admin/admin_main_page.dart' deferred as admin_main;

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      // Not logged in: send to auth and show a simple loading state.
      Future.microtask(() {
        if (context.mounted) {
          context.go('/auth');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: CurrentUserController.watchCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading profile: ${snapshot.error}'),
            ),
          );
        }

        final profile = snapshot.data;

        if (profile == null) {
          // No profile yet: send to role selection.
          Future.microtask(() {
            if (context.mounted) {
              context.go('/role');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Automatically attempt to fetch and save user location and city/town
        // once after login, without showing any UI. If the user denies
        // permission or location services are off, this silently does nothing.
        Future.microtask(() => _ensureUserLocationAndAddress(profile));

        switch (profile.role) {
          case UserRole.customer:
            return const _UserMainHost();
          case UserRole.provider:
            return const _WorkerMainHost();
          case UserRole.admin:
            return const _AdminMainHost();
        }
      },
    );
  }
}

class _UserMainHost extends StatefulWidget {
  const _UserMainHost();

  @override
  State<_UserMainHost> createState() => _UserMainHostState();
}

class _UserMainHostState extends State<_UserMainHost> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    user_main.loadLibrary().then((_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return user_main.MainPage();
  }
}

class _WorkerMainHost extends StatefulWidget {
  const _WorkerMainHost();

  @override
  State<_WorkerMainHost> createState() => _WorkerMainHostState();
}

class _WorkerMainHostState extends State<_WorkerMainHost> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    worker_main.loadLibrary().then((_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return worker_main.WorkerMainPage();
  }
}

class _AdminMainHost extends StatefulWidget {
  const _AdminMainHost();

  @override
  State<_AdminMainHost> createState() => _AdminMainHostState();
}

class _AdminMainHostState extends State<_AdminMainHost> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    admin_main.loadLibrary().then((_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return admin_main.AdminMainPage();
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

    // If we already have location and basic address info, don't do anything.
    if (profile.locationLat != null &&
        profile.locationLng != null &&
        profile.city != null &&
        profile.town != null) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
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
