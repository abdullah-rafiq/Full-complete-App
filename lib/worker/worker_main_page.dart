import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:assist/common/messages_page.dart';
import 'package:assist/common/profile_page.dart';
import 'package:assist/common/app_bottom_nav.dart';
import 'package:assist/controllers/worker_verification_controller.dart';
import 'package:assist/localized_strings.dart';
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
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      WorkerVerificationController.maybeRunAiVerificationForCurrentUser();

      setState(() {
        _pages[1] ??= const WorkerJobsPage();
        _pages[2] ??= const WorkerEarningsPage();
        _pages[3] ??= const MessagesPage();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buildPages() {
      final children = <Widget>[];
      for (var i = 0; i < _pages.length; i++) {
        final cached = _pages[i];
        if (cached != null) {
          children.add(cached);
          continue;
        }
        if (i != _currentIndex) {
          children.add(const SizedBox.shrink());
          continue;
        }

        Widget page;
        switch (i) {
          case 0:
            page = const WorkerHomeScreen();
            break;
          case 1:
            page = const WorkerJobsPage();
            break;
          case 2:
            page = const WorkerEarningsPage();
            break;
          case 3:
            page = const MessagesPage();
            break;
          case 4:
            page = const ProfilePage();
            break;
          default:
            page = const SizedBox.shrink();
        }

        _pages[i] = page;
        children.add(page);
      }
      return children;
    }

    final pages = buildPages();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: pages),
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
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }
}
