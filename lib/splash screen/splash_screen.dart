import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Decide where to go based on auth + role as soon as the widget is ready
    Future.microtask(() async {
      if (!mounted) return;

      final auth = FirebaseAuth.instance;
      final current = auth.currentUser;

      if (current == null) {
        if (!mounted) return;
        context.go('/auth');
        return;
      }

      AppUser? profile;
      try {
        profile = await UserService.instance.getById(current.uid);
      } catch (_) {
        profile = null;
      }

      if (profile == null) {
        // No profile yet: send to auth/role selection flow
        if (!mounted) return;
        context.go('/auth');
        return;
      }

      switch (profile.role) {
        case UserRole.customer:
          if (!mounted) return;
          context.go('/home');
          break;
        case UserRole.provider:
          if (!mounted) return;
          context.go('/worker');
          break;
        case UserRole.admin:
          if (!mounted) return;
          context.go('/admin');
          break;
        // ignore: unreachable_switch_default
        default:
          if (!mounted) return;
          context.go('/auth');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.cleaning_services_rounded,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Assist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
