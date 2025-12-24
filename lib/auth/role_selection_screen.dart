import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:assist/models/app_user.dart';
import 'package:assist/services/auth_service.dart';
import 'package:assist/common/ui_helpers.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/login_main.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: const Color.fromARGB(115, 0, 213, 255),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome to Assist',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select how you want to use the app:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              UIHelpers.showSnack(
                                context,
                                'No logged-in user found. Please log in again.',
                              );
                              return;
                            }

                            try {
                              await AuthService.instance.ensureUserDocument(
                                firebaseUser: user,
                                role: UserRole.customer,
                              );

                              if (!context.mounted) return;

                              context.go('/auth');
                            } catch (e) {
                              if (!context.mounted) return;
                              UIHelpers.showSnack(
                                context,
                                'Failed to save your profile: $e',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            backgroundColor: const Color(0xFF29B6F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I need home services',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              UIHelpers.showSnack(
                                context,
                                'No logged-in user found. Please log in again.',
                              );
                              return;
                            }

                            try {
                              await AuthService.instance.ensureUserDocument(
                                firebaseUser: user,
                                role: UserRole.provider,
                              );

                              if (!context.mounted) return;

                              context.go('/auth');
                            } catch (e) {
                              if (!context.mounted) return;
                              UIHelpers.showSnack(
                                context,
                                'Failed to save your profile: $e',
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            foregroundColor: const Color(0xFF29B6F6),
                            side: const BorderSide(color: Color(0xFF29B6F6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I provide home services',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
