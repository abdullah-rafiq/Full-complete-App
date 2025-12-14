// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/controllers/admin_worker_controller.dart';

class AdminPendingWorkersPage extends StatelessWidget {
  const AdminPendingWorkersPage({super.key});

  bool _isAdmin(AppUser? user) {
    return user != null && user.role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in as admin to view this page.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .snapshots(),
      builder: (context, adminSnap) {
        if (adminSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!adminSnap.hasData || !adminSnap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('No admin profile found.')),
          );
        }

        final adminUser = AppUser.fromMap(
          adminSnap.data!.id,
          adminSnap.data!.data()!,
        );

        if (!_isAdmin(adminUser)) {
          return const Scaffold(
            body: Center(child: Text('Only admins can access this page.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pending worker verifications'),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'provider')
                .where('verificationStatus', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text('No pending worker verifications.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final worker = AppUser.fromMap(doc.id, doc.data());

                  final name = (worker.name?.trim().isNotEmpty ?? false)
                      ? worker.name!.trim()
                      : 'Worker';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .shadowColor
                              .withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              worker.id,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${worker.phone ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${worker.status}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('Reject'),
                                onPressed: () async {
                                  final reason = await AdminWorkerController
                                      .promptRejectReason(context);
                                  if (reason == null) return;
                                  await AdminWorkerController.rejectWorker(
                                    context,
                                    worker.id,
                                    reason: reason,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                onPressed: () async {
                                  await AdminWorkerController.approveWorker(
                                    context,
                                    worker.id,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
