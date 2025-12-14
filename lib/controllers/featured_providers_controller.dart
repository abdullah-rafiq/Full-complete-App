import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/review.dart';
import 'package:flutter_application_1/services/worker_ranking_service.dart';
import 'package:flutter_application_1/services/analytics_service.dart';

class FeaturedProviderItem {
  final AppUser user;
  final double score;
  final double avgRating;
  final int completedJobs;
  final double? distanceKm;
  final double? avgPrice;

  const FeaturedProviderItem({
    required this.user,
    required this.score,
    required this.avgRating,
    required this.completedJobs,
    this.distanceKm,
    this.avgPrice,
  });
}

class FeaturedProvidersController {
  const FeaturedProvidersController._();

  /// Load featured providers based on reviews, number of completed jobs,
  /// and distance from the current user (within a max radius).
  static Future<List<FeaturedProviderItem>> loadFeaturedProviders({
    double maxRadiusKm = 10.0,
    int maxCount = 5,
  }) async {
    final now = DateTime.now();

    double? userLat;
    double? userLng;

    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .get();
      final data = userDoc.data();
      if (data != null) {
        userLat = (data['locationLat'] as num?)?.toDouble();
        userLng = (data['locationLng'] as num?)?.toDouble();
      }
    }

    final providersSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .where('verified', isEqualTo: true)
        .get();

    final items = <FeaturedProviderItem>[];

    for (final doc in providersSnap.docs) {
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

      if (distanceKm != null && distanceKm > maxRadiusKm) {
        continue;
      }

      // Load reviews for this provider.
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('providerId', isEqualTo: user.id)
          .get();
      final reviews = reviewsSnap.docs
          .map((d) => ReviewModel.fromMap(d.id, d.data()))
          .toList();

      // Load completed bookings for this provider.
      final bookingsSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: user.id)
          .where('status', isEqualTo: BookingStatus.completed)
          .get();
      final bookings = bookingsSnap.docs
          .map((d) => BookingModel.fromMap(d.id, d.data()))
          .toList();

      final completedJobs = bookings.length;
      double? avgPrice;
      if (bookings.isNotEmpty) {
        final total = bookings
            .map((b) => b.price.toDouble())
            .fold<double>(0, (sum, v) => sum + v);
        avgPrice = total / bookings.length;
      }

      if (reviews.isEmpty && completedJobs == 0) {
        continue;
      }

      final ratingScore = WorkerRankingService.computeScoreWithDistance(
        reviews,
        now,
        distanceKm: distanceKm,
        maxRadiusKm: maxRadiusKm,
      );

      double jobsScore = 0.0;
      if (completedJobs > 0) {
        jobsScore = (log(completedJobs + 1) / ln10).clamp(0.0, 1.0);
      }

      const wRating = 0.7;
      const wJobs = 0.3;
      final finalScore = (wRating * ratingScore) + (wJobs * jobsScore);

      if (finalScore <= 0) continue;

      // Compute simple average rating for display.
      double avgRating = 0.0;
      if (reviews.isNotEmpty) {
        final total = reviews
            .map((r) => r.rating.toDouble())
            .fold<double>(0, (sum, v) => sum + v);
        avgRating = total / reviews.length;
      }

      items.add(
        FeaturedProviderItem(
          user: user,
          score: finalScore,
          avgRating: avgRating,
          completedJobs: completedJobs,
          distanceKm: distanceKm,
          avgPrice: avgPrice,
        ),
      );
    }

    items.removeWhere((item) => item.score <= 0 && item.completedJobs == 0);

    items.sort((a, b) => b.score.compareTo(a.score));
    if (items.length > maxCount) {
      items.removeRange(maxCount, items.length);
    }

    try {
      if (items.isNotEmpty) {
        await AnalyticsService.instance.logEvent('featured_impression', <String, dynamic>{
          'providerIds': items.map((e) => e.user.id).toList(),
          'count': items.length,
        });
      }
    } catch (_) {}

    return items;
  }
}
