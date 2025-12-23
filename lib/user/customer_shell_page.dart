import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:assist/common/app_bottom_nav.dart';
import 'package:assist/localized_strings.dart';

class CustomerShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShellPage({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: L10n.customerNavHome(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category_outlined),
            label: L10n.customerNavCategories(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: L10n.customerNavBookings(),
          ),
          BottomNavigationBarItem(
            icon: _MessagesIconWithBadge(),
            label: L10n.customerNavMessages(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: L10n.customerNavProfile(),
          ),
        ],
      ),
    );
  }
}

class _MessagesIconWithBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Icon(Icons.message_outlined);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasUnread = docs.any((doc) {
          final data = doc.data();
          final lastSender = data['lastMessageSenderId'] as String?;
          return lastSender != null && lastSender != user.uid;
        });

        if (!hasUnread) {
          return const Icon(Icons.message_outlined);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: const [
            Icon(Icons.message_outlined),
            Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }
}
