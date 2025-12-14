// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/review.dart';
import 'package:flutter_application_1/controllers/home_controller.dart';
import 'package:flutter_application_1/services/worker_ranking_service.dart';
import 'package:flutter_application_1/services/analytics_service.dart';

class TopWorkersSection extends StatelessWidget {
  const TopWorkersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top workers',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: HomeController.watchProviderUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Could not load top workers.',
                    style: TextStyle(fontSize: 13),
                  ),
                );
              }

              final providerDocs = snapshot.data?.docs ?? [];

              if (providerDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No workers available yet.',
                    style: TextStyle(fontSize: 13),
                  ),
                );
              }

              return FutureBuilder<List<_TopWorkerItem>>(
                future: _loadTopWorkers(providerDocs),
                builder: (context, rankingSnap) {
                  if (rankingSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (rankingSnap.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Could not load top workers.',
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  final items = rankingSnap.data ?? [];

                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No workers with reviews yet.',
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  final topItems =
                      items.length > 5 ? items.sublist(0, 5) : items;

                  // Log impression of top workers for analytics / future ML ranking.
                  try {
                    AnalyticsService.instance.logEvent(
                      'top_workers_impression',
                      <String, dynamic>{
                        'providerIds':
                            topItems.map((e) => e.user.id).toList(),
                        'count': topItems.length,
                      },
                    );
                  } catch (_) {}

                  return Column(
                    children: topItems.map((item) {
                      final name =
                          (item.user.name?.trim().isNotEmpty ?? false)
                              ? item.user.name!.trim()
                              : 'Worker';

                      String? distanceLabel;
                      if (item.distanceKm != null) {
                        final d = item.distanceKm!;
                        if (d < 1.0) {
                          distanceLabel = '${(d * 1000).round()} m away';
                        } else {
                          distanceLabel =
                              '${d.toStringAsFixed(1)} km away';
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: item.user.profileImageUrl !=
                                          null &&
                                      item.user.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(
                                      item.user.profileImageUrl!,
                                    )
                                  : const AssetImage('assets/profile.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (distanceLabel != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          distanceLabel,
                                          style: const TextStyle(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.avgRating
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${item.reviewCount} reviews)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopWorkerItem {
  final AppUser user;
  final double score;
  final double avgRating;
  final int reviewCount;
  final double? distanceKm;

  _TopWorkerItem({
    required this.user,
    required this.score,
    required this.avgRating,
    required this.reviewCount,
    this.distanceKm,
  });
}

Future<List<_TopWorkerItem>> _loadTopWorkers(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) async {
  final now = DateTime.now();
  const double maxRadiusKm = 10.0;

  double? userLat;
  double? userLng;

  final current = FirebaseAuth.instance.currentUser;
  if (current != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(current.uid)
        .get();
    final userData = userDoc.data();
    if (userData != null) {
      userLat = (userData['locationLat'] as num?)?.toDouble();
      userLng = (userData['locationLng'] as num?)?.toDouble();
    }
  }

  final futures = docs.map((doc) async {
    final data = doc.data();
    final user = AppUser.fromMap(doc.id, data);

    final providerLat = (data['locationLat'] as num?)?.toDouble();
    final providerLng = (data['locationLng'] as num?)?.toDouble();

    double? distanceKm;
    if (userLat != null &&
        userLng != null &&
        providerLat != null &&
        providerLng != null) {
      distanceKm = WorkerRankingService.haversineKm(
        userLat,
        userLng,
        providerLat,
        providerLng,
      );
    }

    // If provider is clearly outside the max radius, skip expensive
    // review queries and return a low-score item that will be filtered out.
    if (distanceKm != null && distanceKm > maxRadiusKm) {
      return _TopWorkerItem(
        user: user,
        score: 0,
        avgRating: 0,
        reviewCount: 0,
        distanceKm: distanceKm,
      );
    }

    final reviewsSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: user.id)
        .get();

    final reviews = reviewsSnap.docs
        .map((d) => ReviewModel.fromMap(d.id, d.data()))
        .toList();

    final score = WorkerRankingService.computeScoreWithDistance(
      reviews,
      now,
      distanceKm: distanceKm,
      maxRadiusKm: maxRadiusKm,
    );

    double avgRating = 0.0;
    if (reviews.isNotEmpty) {
      avgRating = reviews
              .map((r) => r.rating.toDouble())
              .reduce((a, b) => a + b) /
          reviews.length;
    }

    return _TopWorkerItem(
      user: user,
      score: score,
      avgRating: avgRating,
      reviewCount: reviews.length,
      distanceKm: distanceKm,
    );
  }).toList();

  final list = await Future.wait(futures);

  list.removeWhere((item) {
    if (item.score <= 0 && item.reviewCount == 0) {
      return true;
    }
    if (item.distanceKm != null && item.distanceKm! > maxRadiusKm) {
      return true;
    }
    return false;
  });
  list.sort((a, b) => b.score.compareTo(a.score));
  return list;
}
