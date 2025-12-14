import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/review.dart';
import 'package:flutter_application_1/services/worker_ranking_service.dart';
import 'package:flutter_application_1/admin/admin_worker_detail_page.dart';
import 'package:flutter_application_1/controllers/admin_worker_controller.dart';

class AdminWorkersPage extends StatelessWidget {
  const AdminWorkersPage({super.key});

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

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .get(),
      builder: (context, adminSnap) {
        if (adminSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminSnap.hasError) {
          return Center(
            child: Text('Error loading admin profile: ${adminSnap.error}'),
          );
        }

        if (!adminSnap.hasData || !adminSnap.data!.exists) {
          return const Center(child: Text('No admin profile found.'));
        }

        final adminUser = AppUser.fromMap(
          adminSnap.data!.id,
          adminSnap.data!.data()!,
        );

        if (!_isAdmin(adminUser)) {
          return const Center(child: Text('Only admins can access this page.'));
        }

        final theme = Theme.of(context);
        final onSurface = theme.colorScheme.onSurface;

        return Scaffold(
          appBar: AppBar(
            elevation: 4,
            title: const Text('All workers'),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'provider')
                .get(),
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
                  child: Text('No workers found.'),
                );
              }

              return FutureBuilder<List<_WorkerWithScore>>(
                future: _loadWorkersWithScore(docs),
                builder: (context, scoreSnap) {
                  if (scoreSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (scoreSnap.hasError) {
                    return Center(
                      child: Text('Error loading ratings: ${scoreSnap.error}'),
                    );
                  }

                  final items = scoreSnap.data ?? [];

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('No workers found.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final worker = item.user;
                      final doc = item.doc;

                      final name = (worker.name?.trim().isNotEmpty ?? false)
                          ? worker.name!.trim()
                          : 'Worker';

                      final verificationStatus =
                          doc.data()['verificationStatus'] as String? ?? 'none';

                      Color statusColor;
                      String statusLabel;
                      switch (verificationStatus) {
                        case 'approved':
                          statusColor = Colors.green;
                          statusLabel = 'Approved';
                          break;
                        case 'pending':
                          statusColor = Colors.orange;
                          statusLabel = 'Pending';
                          break;
                        case 'rejected':
                          statusColor = Colors.redAccent;
                          statusLabel = 'Rejected';
                          break;
                        default:
                          statusColor = Colors.blueGrey;
                          statusLabel = 'Not submitted';
                      }

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminWorkerDetailPage(worker: worker),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withOpacity(0.08),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${item.reviewCount} reviews)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${worker.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 2),
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
                              if (verificationStatus == 'pending')
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.redAccent,
                                        ),
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
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF29B6F6),
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                        ),
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
                        ),
                      );
                    },
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

class _WorkerWithScore {
  final AppUser user;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double score;
  final double avgRating;
  final int reviewCount;

  _WorkerWithScore({
    required this.user,
    required this.doc,
    required this.score,
    required this.avgRating,
    required this.reviewCount,
  });
}

Future<List<_WorkerWithScore>> _loadWorkersWithScore(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) async {
  final now = DateTime.now();

  final futures = docs.map((doc) async {
    final user = AppUser.fromMap(doc.id, doc.data());

    final reviewsSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: user.id)
        .get();

    final reviews = reviewsSnap.docs
        .map((d) => ReviewModel.fromMap(d.id, d.data()))
        .toList();

    final score = WorkerRankingService.computeScore(reviews, now);

    double avgRating = 0.0;
    if (reviews.isNotEmpty) {
      avgRating = reviews
              .map((r) => r.rating.toDouble())
              .reduce((a, b) => a + b) /
          reviews.length;
    }

    return _WorkerWithScore(
      user: user,
      doc: doc,
      score: score,
      avgRating: avgRating,
      reviewCount: reviews.length,
    );
  }).toList();

  final list = await Future.wait(futures);

  list.sort((a, b) => b.score.compareTo(a.score));
  return list;
}
