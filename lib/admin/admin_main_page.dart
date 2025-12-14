import 'package:flutter/material.dart';

import 'admin_workers_page.dart';
import 'admin_notifications_page.dart';
import 'admin_analytics_page.dart' deferred as admin_analytics;
import 'package:flutter_application_1/common/profile_page.dart';
import 'package:flutter_application_1/common/app_bottom_nav.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _AdminAnalyticsHost(),
      const AdminWorkersPage(),
      const AdminNotificationsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: 'Workers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _AdminAnalyticsHost extends StatefulWidget {
  const _AdminAnalyticsHost();

  @override
  State<_AdminAnalyticsHost> createState() => _AdminAnalyticsHostState();
}

class _AdminAnalyticsHostState extends State<_AdminAnalyticsHost> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    admin_analytics.loadLibrary().then((_) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          elevation: 4,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return admin_analytics.AdminAnalyticsPage();
  }
}
