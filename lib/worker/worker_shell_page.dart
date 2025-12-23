import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:assist/common/app_bottom_nav.dart';
import 'package:assist/controllers/worker_verification_controller.dart';
import 'package:assist/localized_strings.dart';

class WorkerShellPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const WorkerShellPage({super.key, required this.navigationShell});

  @override
  State<WorkerShellPage> createState() => _WorkerShellPageState();
}

class _WorkerShellPageState extends State<WorkerShellPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WorkerVerificationController.maybeRunAiVerificationForCurrentUser();
    });
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTap,
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
