import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/common/messages_page.dart';
import 'package:flutter_application_1/common/profile_page.dart';
import 'package:flutter_application_1/common/app_bottom_nav.dart';
import 'package:flutter_application_1/localized_strings.dart';
import 'worker_home_screen.dart';
import 'worker_jobs_page.dart';
import 'worker_earnings_page.dart';

class WorkerMainPage extends StatefulWidget {
  const WorkerMainPage({super.key});

  @override
  State<WorkerMainPage> createState() => _WorkerMainPageState();
}

class _WorkerMainPageState extends State<WorkerMainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const WorkerHomeScreen(),
      const WorkerJobsPage(),
      const WorkerEarningsPage(),
      const MessagesPage(),
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: L10n.workerNavHome(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work_outline),
            label: L10n.workerNavJobs(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: L10n.workerNavEarnings(),
          ),
          BottomNavigationBarItem(
            icon: _WorkerMessagesIconWithBadge(),
            label: L10n.workerNavMessages(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: L10n.workerNavProfile(),
          ),
        ],
      ),
    );
  }
}

class _WorkerMessagesIconWithBadge extends StatelessWidget {
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
              child: CircleAvatar(
                radius: 4,
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}

