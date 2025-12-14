// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/controllers/profile_controller.dart';
import 'package:flutter_application_1/controllers/current_user_controller.dart';
import 'package:flutter_application_1/common/ui_helpers.dart';
import 'package:flutter_application_1/worker/worker_verification_page.dart';

import 'wallet_page.dart';
import 'section_card.dart';
import '../user/my_bookings_page.dart';
import '../localized_strings.dart';
import '../dev_seed.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  StreamSubscription<AppUser?>? _verificationSub;

  @override
  void initState() {
    super.initState();

    final current = FirebaseAuth.instance.currentUser;
    if (current != null && current.emailVerified) {
      _verificationSub = UserService.instance
          .watchUser(current.uid)
          .listen((profile) async {
        if (profile != null && !profile.verified) {
          await UserService.instance
              .updateUser(current.uid, {'verified': true});
        }

        await _verificationSub?.cancel();
        _verificationSub = null;
      });
    }
  }

  @override
  void dispose() {
    _verificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color accentBlue = Color(0xFF29B6F6);
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your profile.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<AppUser?>(
          stream: CurrentUserController.watchCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final profile = snapshot.data;

            // Debug: log the loaded role (if any) for this profile
            if (profile != null) {
              // ignore: avoid_print
              print('PROFILE_ROLE: ${profile.role.name}');
            }

            final displayName =
                profile?.name ?? current.displayName ?? 'User';
            final profileImageUrl = profile?.profileImageUrl;

            ImageProvider avatarImage;
            if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
              avatarImage = NetworkImage(profileImageUrl);
            } else {
              avatarImage = const AssetImage('assets/profile.png');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SectionCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: avatarImage,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: IconButton(
                                iconSize: 18,
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: const Icon(Icons.add_a_photo, size: 16),
                                onPressed: () => ProfileController
                                    .changeProfileImage(context, current.uid),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile != null) ...[
                          if (profile.role != UserRole.admin) ...[
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: profile.verified
                                  ? null
                                  : () {
                                      if (profile.role == UserRole.provider) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const WorkerVerificationPage(),
                                          ),
                                        );
                                      } else {
                                        ProfileController.startPhoneVerification(
                                          context,
                                          profile,
                                        );
                                      }
                                    },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    profile.verified
                                        ? Icons.verified
                                        : Icons.error_outline,
                                    size: 16,
                                    color: profile.verified
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.verified
                                        ? 'Verified account'
                                        : 'Not verified (tap to verify)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: profile.verified
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile == null || profile.role != UserRole.admin)
                    SectionCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _QuickAction(
                            iconPath: 'assets/icons/wallet.png',
                            label: L10n.profileQuickWallet(),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const WalletPage()),
                              );
                            },
                          ),
                          _QuickAction(
                            iconPath: 'assets/icons/booking.png',
                            label: L10n.profileQuickBooking(),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MyBookingsPage()),
                              );
                            },
                          ),
                          _QuickAction(
                            iconPath: 'assets/icons/card.png',
                            label: L10n.profileQuickPayment(),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MyBookingsPage()),
                              );
                            },
                          ),
                          _QuickAction(
                            iconPath: 'assets/icons/contact-us.png',
                            label: L10n.profileQuickSupport(),
                            onTap: () {
                              context.push('/contact');
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (profile != null && profile.role != UserRole.admin) ...[
                    ListTile(
                      title: Text(L10n.profileEditTitle()),
                      subtitle: Text(
                        profile.name == null || profile.name!.isEmpty
                            ? 'Add your name and phone number'
                            : 'Update your name or phone number',
                      ),
                      leading: const Icon(Icons.person_outline),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () => _showEditProfileDialog(context, profile),
                    ),
                    const Divider(),
                  ],
                  if (profile != null && profile.role == UserRole.admin) ...[
                    ListTile(
                      title: const Text('Seed demo data'),
                      subtitle: const Text(
                        'Populate Firestore with demo users, services, bookings, and reviews (dev only).',
                      ),
                      leading: const Icon(Icons.dataset_outlined),
                      trailing:
                          const Icon(Icons.play_arrow, color: accentBlue),
                      onTap: () async {
                        try {
                          await seedDemoData();
                          if (!context.mounted) return;
                          UIHelpers.showSnack(
                            context,
                            'Demo data seeded successfully.',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          UIHelpers.showSnack(
                            context,
                            'Failed to seed demo data: $e',
                          );
                        }
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    title: Text(L10n.profileSettingsTitle()),
                    subtitle: const Text('Privacy and logout'),
                    leading: Image.asset(
                      'assets/icons/setting.png',
                      width: 30,
                      height: 30,
                      cacheWidth: 125,  
                      cacheHeight: 125,
                      fit: BoxFit.scaleDown,
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: accentBlue),
                    onTap: () {
                      context.push('/settings');
                    },
                  ),
                  const Divider(),
                  if (profile == null || profile.role != UserRole.admin) ...[
                    ListTile(
                      title: Text(L10n.profileHelpSupportTitle()),
                      subtitle: const Text('Help center and legal support'),
                      leading: Image.asset(
                        'assets/icons/support.png',
                        cacheWidth: 125,
                        cacheHeight: 125,
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () {
                        context.push('/contact');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(L10n.faqTitle()),
                      subtitle: const Text('Questions and Answers'),
                      leading: Image.asset(
                        'assets/icons/faq.png',
                        cacheWidth: 125,
                        cacheHeight: 125,
                      ),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () {
                        context.push('/faq');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(L10n.termsTitle()),
                      subtitle: const Text('Read app terms & conditions'),
                      leading: const Icon(Icons.description_outlined),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () {
                        context.push('/terms');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(L10n.privacyTitle()),
                      subtitle: const Text('View privacy policy'),
                      leading: const Icon(Icons.privacy_tip_outlined),
                      trailing:
                          const Icon(Icons.chevron_right, color: accentBlue),
                      onTap: () {
                        context.push('/privacy');
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    title: Text(L10n.profileLogoutTitle()),
                    subtitle: const Text('Sign out from this account'),
                    leading: const Icon(Icons.logout),
                    trailing:
                        const Icon(Icons.chevron_right, color: accentBlue),
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

Future<void> _showEditProfileDialog(BuildContext context, AppUser profile) async {
  final nameController = TextEditingController(text: profile.name ?? '');
  final phoneController = TextEditingController(text: profile.phone ?? '');
  final addressController =
      TextEditingController(text: profile.addressLine1 ?? '');
  final townController = TextEditingController(text: profile.town ?? '');
  String? selectedCity = profile.city;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomInset + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Update your basic information so providers can recognize you easily.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '+92 300 1234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Lahore', child: Text('Lahore')),
                      DropdownMenuItem(value: 'Islamabad', child: Text('Islamabad')),
                      DropdownMenuItem(value: 'Karachi', child: Text('Karachi')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'House no. / Street (address line 1)',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: townController,
                    decoration: const InputDecoration(
                      labelText: 'Town / Area',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await ProfileController
                          .updateLocationFromCurrentPosition(
                        context,
                        profile.id,
                      );
                      if (result == null) return;

                      setState(() {
                        if (result.city != null &&
                            (result.city == 'Lahore' ||
                                result.city == 'Islamabad' ||
                                result.city == 'Karachi')) {
                          selectedCity = result.city;
                        }

                        if (result.town != null &&
                            result.town!.isNotEmpty) {
                          townController.text = result.town!;
                        }

                        if (result.addressLine1 != null &&
                            result.addressLine1!.trim().isNotEmpty) {
                          addressController.text = result.addressLine1!;
                        }
                      });
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use current location'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final phone = phoneController.text.trim();

                            if (name.isEmpty) {
                              UIHelpers.showSnack(
                                context,
                                'Name cannot be empty.',
                              );
                              return;
                            }

                            try {
                              final address = addressController.text.trim();
                              final town = townController.text.trim();

                              await UserService.instance.updateUser(profile.id, {
                                'name': name,
                                'phone': phone.isEmpty ? null : phone,
                                'city': selectedCity,
                                'addressLine1':
                                    address.isEmpty ? null : address,
                                'town': town.isEmpty ? null : town,
                              });

                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              UIHelpers.showSnack(
                                context,
                                'Profile updated successfully.',
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              UIHelpers.showSnack(
                                context,
                                'Failed to update profile: $e',
                              );
                            }
                          },
                          child: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Change password'),
                    subtitle:
                        const Text('Send a password reset link to your email.'),
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      final email = user?.email;

                      if (email == null || email.isEmpty) {
                        UIHelpers.showSnack(
                          context,
                          'No email found for this account. You may be using a social login.',
                        );
                        return;
                      }

                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);
                        if (!context.mounted) return;
                        UIHelpers.showSnack(
                          context,
                          'Password reset email sent. Please check your inbox.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        UIHelpers.showSnack(
                          context,
                          'Could not send reset email: $e',
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text('Delete account'),
                    subtitle: const Text(
                        'Permanently remove your account and data.'),
                    onTap: () => ProfileController.deleteAccount(context),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _QuickAction extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.10).clamp(40.0, 50.0); // 40-50 px
    final fontSize = (screenWidth * 0.03).clamp(12.0, 14.0); // 12-14 px
    final spacing = iconSize * 0.2; // spacing proportional to icon

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: Image.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            cacheWidth: 125,
            cacheHeight: 125,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ],
    );
  }
}
