// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme_mode_notifier.dart';
import '../app_locale.dart';
import '../localized_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loadingNotifications = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _loadingNotifications = false;
        });
        return;
      }

      final data = doc.data();
      final value = data?['notificationsEnabled'];

      if (value is bool) {
        setState(() {
          _notificationsEnabled = value;
          _loadingNotifications = false;
        });
      } else {
        setState(() {
          _loadingNotifications = false;
        });
      }
    } catch (_) {
      setState(() {
        _loadingNotifications = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(L10n.settingsAppBarTitle()),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              SwitchListTile(
                title: Text(L10n.settingsPushNotificationsTitle()),
                subtitle: Text(L10n.settingsPushNotificationsSubtitle()),
                value: _notificationsEnabled,
                onChanged: _loadingNotifications
                    ? null
                    : (value) async {
                        setState(() {
                          _notificationsEnabled = value;
                        });

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set(
                            {
                              'notificationsEnabled': value,
                            },
                            SetOptions(merge: true),
                          );
                        } catch (_) {
                          // Revert on failure
                          setState(() {
                            _notificationsEnabled = !value;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not update notification preference. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.themeMode,
                builder: (context, themeMode, _) {
                  final isDark = themeMode == ThemeMode.dark;
                  return SwitchListTile(
                    title: Text(L10n.settingsDarkModeTitle()),
                    subtitle: Text(L10n.settingsDarkModeSubtitle()),
                    value: isDark,
                    onChanged: (value) {
                      AppTheme.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<Locale>(
                valueListenable: AppLocale.locale,
                builder: (context, currentLocale, _) {
                  final isUrdu = currentLocale.languageCode == 'ur';
                  return ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(L10n.settingsLanguageTitle()),
                    subtitle:
                        Text(isUrdu ? L10n.languageNameUrdu() : L10n.languageNameEnglish()),
                    onTap: () async {
                      final newLocale = isUrdu
                          ? const Locale('en')
                          : const Locale('ur');
                      await AppLocale.setLocale(newLocale);
                    },
                  );
                },
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
