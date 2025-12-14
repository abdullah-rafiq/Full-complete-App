import 'dart:math';

import 'package:flutter_application_1/models/review.dart';

class WorkerRankingService {
  const WorkerRankingService._();

  static double computeScore(List<ReviewModel> reviews, DateTime now) {
    return computeRatingScore(reviews, now);
  }

  static double computeRatingScore(List<ReviewModel> reviews, DateTime now) {
    if (reviews.isEmpty) {
      return 0.0;
    }

    final n = reviews.length;

    // --- 1) Star rating (average) ---
    final avgRating =
        reviews.map((r) => r.rating.toDouble()).reduce((a, b) => a + b) / n;
    final baseRatingScore = avgRating / 5.0; // 0..1

    // --- 2) Questionnaire scores (punctuality, quality, communication, professionalism) ---
    double questionnaireSum = 0;
    int questionnaireCount = 0;

    for (final r in reviews) {
      final fields = <int?>[
        r.qPunctuality,
        r.qQuality,
        r.qCommunication,
        r.qProfessionalism,
      ];

      for (final v in fields) {
        if (v != null && v > 0) {
          questionnaireSum += v.toDouble();
          questionnaireCount++;
        }
      }
    }

    double questionnaireScore = 0.0;
    if (questionnaireCount > 0) {
      final avgQ = questionnaireSum / questionnaireCount; // 1..5
      questionnaireScore = (avgQ / 5.0).clamp(0.0, 1.0);
    }

    // --- 3) Would recommend ratio ---
    int recommendYes = 0;
    int recommendTotal = 0;
    for (final r in reviews) {
      if (r.wouldRecommend != null) {
        recommendTotal++;
        if (r.wouldRecommend == true) recommendYes++;
      }
    }
    double recommendScore = 0.0;
    if (recommendTotal > 0) {
      recommendScore = recommendYes / recommendTotal; // 0..1
    }

    // --- 4) Timeliness: completion vs expected duration ---
    double timelinessSum = 0.0;
    int timelinessCount = 0;
    for (final r in reviews) {
      final actual = r.completionTimeMinutes;
      final expected = r.expectedDurationMinutes;
      if (actual != null && expected != null && actual > 0 && expected > 0) {
        final ratio = actual / expected; // <1 early, 1 on time, >1 late
        double score;
        if (ratio <= 1.0) {
          score = 1.0;
        } else if (ratio >= 2.0) {
          // More than 2x late is very bad.
          score = 0.0;
        } else {
          // Linear drop from 1.0 to 0.0 between 1x and 2x expected time.
          score = 1.0 - (ratio - 1.0);
        }
        timelinessSum += score.clamp(0.0, 1.0);
        timelinessCount++;
      }
    }

    double timelinessScore = 0.0;
    if (timelinessCount > 0) {
      timelinessScore = timelinessSum / timelinessCount; // 0..1
    }

    // --- 5) Disputes penalty ---
    final disputeCount =
        reviews.where((r) => r.hadDispute != null && r.hadDispute!).length;
    final disputeRate = disputeCount / n; // 0..1

    // --- 6) Review count factor (more reviews = more trust) ---
    final countFactor = log(n + 1) / ln10; // grows slowly with n

    // --- 7) Recency boost based on newest review ---
    final latest = reviews
        .where((r) => r.createdAt != null)
        .map((r) => r.createdAt!)
        .fold<DateTime?>(null, (prev, d) {
      if (prev == null) return d;
      return d.isAfter(prev) ? d : prev;
    });

    double recentBoost = 0.0;
    if (latest != null) {
      final days = now.difference(latest).inHours / 24.0;
      const decayWindowDays = 90.0;
      recentBoost = 1.0 - (days / decayWindowDays);
      if (recentBoost < 0) recentBoost = 0;
      if (recentBoost > 1) recentBoost = 1;
    }

    // --- 8) Combine into composite score ---
    // Weights tuned to keep rating important but adjust for reliability.
    const wStars = 0.45;
    const wQuestionnaire = 0.20;
    const wRecommend = 0.10;
    const wTimeliness = 0.10;
    const wCount = 0.10;
    const wRecent = 0.10;
    const wDisputePenalty = 0.30; // how strongly disputes reduce the score

    final reliabilityScore = (wQuestionnaire * questionnaireScore) +
        (wRecommend * recommendScore) +
        (wTimeliness * timelinessScore);

    final composite = (wStars * baseRatingScore) +
        reliabilityScore +
        (wCount * countFactor) +
        (wRecent * recentBoost) -
        (wDisputePenalty * disputeRate);

    return composite.clamp(0.0, 1.0);
  }

  static double computeScoreWithDistance(
    List<ReviewModel> reviews,
    DateTime now, {
    required double? distanceKm,
    double maxRadiusKm = 5.0,
  }) {
    final ratingScore = computeRatingScore(reviews, now);

    if (distanceKm == null || maxRadiusKm <= 0) {
      return ratingScore;
    }

    double distanceScore = 1.0 - (distanceKm / maxRadiusKm);
    if (distanceScore < 0) distanceScore = 0;
    if (distanceScore > 1) distanceScore = 1;

    const wRating = 0.6;
    const wDistance = 0.4;

    final finalScore = (wRating * ratingScore) + (wDistance * distanceScore);
    return finalScore.clamp(0.0, 1.0);
  }

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
