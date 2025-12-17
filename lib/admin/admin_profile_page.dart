// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/controllers/current_user_controller.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view admin profile.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).primaryColorDark,
        elevation: 4,
        title: const Text('Admin profile'),
      ),
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: UserService.instance.watchUser(current.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final profile = snapshot.data;

            if (profile == null) {
              return const Center(child: Text('Admin profile not found.'));
            }

            final displayName = profile.name ?? current.email ?? 'Admin';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: ${profile.role.name}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        if (profile.email != null)
                          Text(
                            profile.email!,
                            style: const TextStyle(fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Settings'),
                    subtitle: const Text('Privacy and app settings'),
                    leading: const Icon(Icons.settings_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/settings');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Help & Support'),
                    subtitle: const Text('Help center and legal support'),
                    leading: const Icon(Icons.help_outline),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/contact');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out from this admin account'),
                    leading: const Icon(Icons.logout),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      CurrentUserController.reset();
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
