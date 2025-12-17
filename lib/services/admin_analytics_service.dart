import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/review.dart';
import 'package:flutter_application_1/common/sentiment_utils.dart';

class AdminAnalyticsService {
  const AdminAnalyticsService._();

  static _SentimentStats? _sentimentCache;
  static DateTime? _sentimentCacheAt;
  static bool _sentimentPrefsHydrated = false;

  static const String _kSentimentAvg = 'admin_analytics_sentiment_avg';
  static const String _kSentimentPos = 'admin_analytics_sentiment_pos';
  static const String _kSentimentNeu = 'admin_analytics_sentiment_neu';
  static const String _kSentimentNeg = 'admin_analytics_sentiment_neg';
  static const String _kSentimentAtMs = 'admin_analytics_sentiment_at_ms';

  static const String _kAnalyticsCacheJson = 'admin_analytics_cache_json';
  static const String _kAnalyticsCacheAtMs = 'admin_analytics_cache_at_ms';

  static AdminAnalyticsData? _analyticsCache;
  static DateTime? _analyticsCacheAt;
  static bool _analyticsPrefsHydrated = false;

  static Future<void> _hydrateSentimentCache() async {
    if (_sentimentPrefsHydrated) return;
    _sentimentPrefsHydrated = true;

    // If cache is already set in memory, don't override it.
    if (_sentimentCache != null && _sentimentCacheAt != null) return;

    final prefs = await SharedPreferences.getInstance();

    final atMs = prefs.getInt(_kSentimentAtMs);
    final avg = prefs.getDouble(_kSentimentAvg);
    final pos = prefs.getInt(_kSentimentPos);
    final neu = prefs.getInt(_kSentimentNeu);
    final neg = prefs.getInt(_kSentimentNeg);

    if (atMs == null ||
        avg == null ||
        pos == null ||
        neu == null ||
        neg == null) {
      return;
    }

    _sentimentCacheAt = DateTime.fromMillisecondsSinceEpoch(atMs);
    _sentimentCache = _SentimentStats(
      avgScore: avg,
      positiveCount: pos,
      neutralCount: neu,
      negativeCount: neg,
    );
  }

  static Future<void> _hydrateAnalyticsCache() async {
    if (_analyticsPrefsHydrated) return;
    _analyticsPrefsHydrated = true;

    if (_analyticsCache != null && _analyticsCacheAt != null) return;

    final prefs = await SharedPreferences.getInstance();
    final atMs = prefs.getInt(_kAnalyticsCacheAtMs);
    final raw = prefs.getString(_kAnalyticsCacheJson);
    if (atMs == null || raw == null || raw.trim().isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;

    _analyticsCacheAt = DateTime.fromMillisecondsSinceEpoch(atMs);
    _analyticsCache = _analyticsFromJson(decoded);
  }

  static Future<void> _persistAnalyticsCache(AdminAnalyticsData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kAnalyticsCacheAtMs,
      (_analyticsCacheAt ?? DateTime.now()).millisecondsSinceEpoch,
    );
    await prefs.setString(
      _kAnalyticsCacheJson,
      jsonEncode(_analyticsToJson(data)),
    );
  }

  static Map<String, dynamic> _analyticsToJson(AdminAnalyticsData d) {
    return <String, dynamic>{
      'bookingRangeDays': d.bookingRangeDays,
      'totalUsers': d.totalUsers,
      'customerCount': d.customerCount,
      'providerCount': d.providerCount,
      'adminCount': d.adminCount,
      'totalBookings': d.totalBookings,
      'completedBookings': d.completedBookings,
      'pendingBookings': d.pendingBookings,
      'recentBookingsLast30Days': d.recentBookingsLast30Days,
      'bookingsByStatus': d.bookingsByStatus,
      'topCitiesByBookings': d.topCitiesByBookings
          .map((c) => <String, dynamic>{'city': c.city, 'count': c.count})
          .toList(),
      'verificationCounts': d.verificationCounts,
      'signupsLast7DaysByDay': d.signupsLast7DaysByDay,
      'signupsLast30DaysByDay': d.signupsLast30DaysByDay,
      'topProviders': d.topProviders
          .map(
            (p) => <String, dynamic>{
              'id': p.id,
              'name': p.name,
              'completedBookings': p.completedBookings,
            },
          )
          .toList(),
      'avgSentiment': d.avgSentiment,
      'positiveReviewCount': d.positiveReviewCount,
      'neutralReviewCount': d.neutralReviewCount,
      'negativeReviewCount': d.negativeReviewCount,
      'engagementStats': <String, dynamic>{
        'totalFeaturedImpressions': d.engagementStats.totalFeaturedImpressions,
        'totalFeaturedClicks': d.engagementStats.totalFeaturedClicks,
        'totalTopWorkersImpressions':
            d.engagementStats.totalTopWorkersImpressions,
        'topProvidersByClicks': d.engagementStats.topProvidersByClicks
            .map(
              (p) => <String, dynamic>{
                'id': p.id,
                'name': p.name,
                'clicks': p.clicks,
                'impressions': p.impressions,
              },
            )
            .toList(),
      },
    };
  }

  static AdminAnalyticsData _analyticsFromJson(Map<String, dynamic> m) {
    final topCitiesRaw = (m['topCitiesByBookings'] as List?) ?? const [];
    final topProvidersRaw = (m['topProviders'] as List?) ?? const [];
    final engagementRaw =
        (m['engagementStats'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final topByClicksRaw =
        (engagementRaw['topProvidersByClicks'] as List?) ?? const [];

    return AdminAnalyticsData(
      bookingRangeDays: (m['bookingRangeDays'] as num?)?.toInt(),
      totalUsers: (m['totalUsers'] as num?)?.toInt() ?? 0,
      customerCount: (m['customerCount'] as num?)?.toInt() ?? 0,
      providerCount: (m['providerCount'] as num?)?.toInt() ?? 0,
      adminCount: (m['adminCount'] as num?)?.toInt() ?? 0,
      totalBookings: (m['totalBookings'] as num?)?.toInt() ?? 0,
      completedBookings: (m['completedBookings'] as num?)?.toInt() ?? 0,
      pendingBookings: (m['pendingBookings'] as num?)?.toInt() ?? 0,
      recentBookingsLast30Days:
          (m['recentBookingsLast30Days'] as num?)?.toInt() ?? 0,
      bookingsByStatus:
          (m['bookingsByStatus'] as Map?)?.cast<String, int>() ??
          const <String, int>{},
      topCitiesByBookings: topCitiesRaw.whereType<Map>().map((e) {
        final mm = e.cast<String, dynamic>();
        return CityCount(
          city: (mm['city'] as String?) ?? '',
          count: (mm['count'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      verificationCounts:
          (m['verificationCounts'] as Map?)?.cast<String, int>() ??
          const <String, int>{},
      signupsLast7DaysByDay:
          (m['signupsLast7DaysByDay'] as Map?)?.cast<String, int>() ??
          const <String, int>{},
      signupsLast30DaysByDay:
          (m['signupsLast30DaysByDay'] as Map?)?.cast<String, int>() ??
          const <String, int>{},
      topProviders: topProvidersRaw.whereType<Map>().map((e) {
        final mm = e.cast<String, dynamic>();
        return TopProvider(
          id: (mm['id'] as String?) ?? '',
          name: (mm['name'] as String?) ?? 'Provider',
          completedBookings: (mm['completedBookings'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      avgSentiment: (m['avgSentiment'] as num?)?.toDouble() ?? 0.0,
      positiveReviewCount: (m['positiveReviewCount'] as num?)?.toInt() ?? 0,
      neutralReviewCount: (m['neutralReviewCount'] as num?)?.toInt() ?? 0,
      negativeReviewCount: (m['negativeReviewCount'] as num?)?.toInt() ?? 0,
      engagementStats: EngagementStats(
        totalFeaturedImpressions:
            (engagementRaw['totalFeaturedImpressions'] as num?)?.toInt() ?? 0,
        totalFeaturedClicks:
            (engagementRaw['totalFeaturedClicks'] as num?)?.toInt() ?? 0,
        totalTopWorkersImpressions:
            (engagementRaw['totalTopWorkersImpressions'] as num?)?.toInt() ?? 0,
        topProvidersByClicks: topByClicksRaw.whereType<Map>().map((e) {
          final mm = e.cast<String, dynamic>();
          return EngagementProvider(
            id: (mm['id'] as String?) ?? '',
            name: (mm['name'] as String?) ?? 'Provider',
            clicks: (mm['clicks'] as num?)?.toInt() ?? 0,
            impressions: (mm['impressions'] as num?)?.toInt() ?? 0,
          );
        }).toList(),
      ),
    );
  }

  static Future<void> _persistSentimentCache(_SentimentStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kSentimentAtMs,
      (_sentimentCacheAt ?? DateTime.now()).millisecondsSinceEpoch,
    );
    await prefs.setDouble(_kSentimentAvg, stats.avgScore);
    await prefs.setInt(_kSentimentPos, stats.positiveCount);
    await prefs.setInt(_kSentimentNeu, stats.neutralCount);
    await prefs.setInt(_kSentimentNeg, stats.negativeCount);
  }

  static Future<AdminAnalyticsData> loadAnalytics({
    bool logTimings = false,
    bool useCachedAnalytics = false,
    int? bookingRangeDays = 30,
  }) async {
    final start = DateTime.now();
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      throw Exception('Please log in as admin to view analytics.');
    }

    final db = FirebaseFirestore.instance;

    final adminDoc = await db.collection('users').doc(current.uid).get();
    if (!adminDoc.exists) {
      throw Exception('Admin profile not found.');
    }

    final adminUser = AppUser.fromMap(adminDoc.id, adminDoc.data()!);
    if (adminUser.role != UserRole.admin) {
      throw Exception('Only admins can view analytics.');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Start = today.subtract(const Duration(days: 6));
    final last30Start = today.subtract(const Duration(days: 29));

    final int? effectiveBookingRangeDays =
        (bookingRangeDays == null || bookingRangeDays <= 0)
        ? null
        : bookingRangeDays;
    final DateTime? bookingRangeStart = effectiveBookingRangeDays == null
        ? null
        : today.subtract(Duration(days: effectiveBookingRangeDays - 1));

    await _hydrateSentimentCache();
    await _hydrateAnalyticsCache();

    final cachedValid =
        _analyticsCache != null &&
        _analyticsCacheAt != null &&
        DateTime.now().difference(_analyticsCacheAt!) <
            const Duration(minutes: 30);
    if (useCachedAnalytics &&
        cachedValid &&
        _analyticsCache?.bookingRangeDays == effectiveBookingRangeDays) {
      return _analyticsCache!;
    }

    final usersCol = db.collection('users');
    final bookingsCol = db.collection('bookings');
    final reviewsCol = db.collection('reviews');
    final analyticsCol = db.collection('analytics_events');

    final sentimentCacheValid =
        _sentimentCache != null &&
        _sentimentCacheAt != null &&
        DateTime.now().difference(_sentimentCacheAt!) <
            const Duration(hours: 6);

    final queryStart = DateTime.now();
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [
      usersCol.get(),
      bookingRangeStart == null
          ? bookingsCol.get()
          : bookingsCol
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(bookingRangeStart),
                )
                .get(),
      analyticsCol
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(last30Start),
          )
          .get(),
    ];
    if (!sentimentCacheValid) {
      futures.add(reviewsCol.get());
    }

    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>(
      futures,
    );
    final queryEnd = DateTime.now();

    final usersSnap = results[0];
    final bookingsSnap = results[1];
    final analyticsSnap = results[2];
    final QuerySnapshot<Map<String, dynamic>>? reviewsSnap = sentimentCacheValid
        ? null
        : results[3];

    // ---- Users & signups ----
    int customerCount = 0;
    int providerCount = 0;
    int adminCount = 0;

    final Map<String, int> verificationCounts = <String, int>{};
    final Map<String, int> signupsLast7DaysByDay = <String, int>{};
    final Map<String, int> signupsLast30DaysByDay = <String, int>{};
    final Map<String, AppUser> userById = <String, AppUser>{};

    for (final doc in usersSnap.docs) {
      final user = AppUser.fromMap(doc.id, doc.data());
      userById[user.id] = user;

      switch (user.role) {
        case UserRole.customer:
          customerCount++;
          break;
        case UserRole.provider:
          providerCount++;
          final verificationStatus =
              (doc.data()['verificationStatus'] as String?) ?? 'none';
          verificationCounts[verificationStatus] =
              (verificationCounts[verificationStatus] ?? 0) + 1;
          break;
        case UserRole.admin:
          adminCount++;
          break;
      }

      final createdTs = doc.data()['createdAt'] as Timestamp?;
      if (createdTs != null) {
        final created = createdTs.toDate();
        final day = DateTime(created.year, created.month, created.day);
        final key =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

        if (!day.isBefore(last7Start) && !day.isAfter(today)) {
          signupsLast7DaysByDay[key] = (signupsLast7DaysByDay[key] ?? 0) + 1;
        }

        if (!day.isBefore(last30Start) && !day.isAfter(today)) {
          signupsLast30DaysByDay[key] = (signupsLast30DaysByDay[key] ?? 0) + 1;
        }
      }
    }

    final totalUsers = usersSnap.size;

    // ---- Bookings ----
    final Map<String, int> bookingsByStatus = <String, int>{};
    final Map<String, int> cityCounts = <String, int>{};
    final Map<String, int> providerCompletedCounts = <String, int>{};

    int recentBookingsLast30Days = 0;

    for (final doc in bookingsSnap.docs) {
      final data = doc.data();

      final status = data['status'] as String? ?? BookingStatus.requested;
      bookingsByStatus[status] = (bookingsByStatus[status] ?? 0) + 1;

      final createdTs = data['createdAt'] as Timestamp?;
      if (createdTs != null) {
        final created = createdTs.toDate();
        if (!created.isBefore(last30Start) && !created.isAfter(today)) {
          recentBookingsLast30Days++;
        }
      }

      // Bookings by city (based on customer / provider city)
      String? city;
      final customerId = data['customerId'] as String?;
      if (customerId != null) {
        city = userById[customerId]?.city;
      }
      city ??= userById[(data['providerId'] as String?) ?? '']?.city;

      if (city != null && city.trim().isNotEmpty) {
        final key = city.trim();
        cityCounts[key] = (cityCounts[key] ?? 0) + 1;
      }

      // Top providers by completed bookings
      final providerId = data['providerId'] as String?;
      if (providerId != null &&
          providerId.isNotEmpty &&
          status == BookingStatus.completed) {
        providerCompletedCounts[providerId] =
            (providerCompletedCounts[providerId] ?? 0) + 1;
      }
    }

    final totalBookings = bookingsSnap.size;
    final completedBookings = bookingsByStatus[BookingStatus.completed] ?? 0;
    final pendingBookings = bookingsByStatus[BookingStatus.requested] ?? 0;

    // Top cities by bookings (max 5)
    final List<CityCount> topCitiesByBookings =
        cityCounts.entries
            .map((e) => CityCount(city: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    if (topCitiesByBookings.length > 5) {
      topCitiesByBookings.removeRange(5, topCitiesByBookings.length);
    }

    // Top providers by completed bookings (max 5)
    final List<TopProvider> topProviders =
        providerCompletedCounts.entries.map((e) {
          final user = userById[e.key];
          final rawName = user?.name?.trim();
          final name = (rawName != null && rawName.isNotEmpty)
              ? rawName
              : 'Provider';
          return TopProvider(id: e.key, name: name, completedBookings: e.value);
        }).toList()..sort(
          (a, b) => b.completedBookings.compareTo(a.completedBookings),
        );
    if (topProviders.length > 5) {
      topProviders.removeRange(5, topProviders.length);
    }

    final sentimentStart = DateTime.now();
    final _SentimentStats sentiment;
    if (sentimentCacheValid) {
      sentiment = _sentimentCache!;
    } else {
      final reviews =
          (reviewsSnap?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              .map((d) => ReviewModel.fromMap(d.id, d.data()))
              .toList();
      sentiment = await _computeSentimentStats(reviews);
      _sentimentCache = sentiment;
      _sentimentCacheAt = DateTime.now();
      await _persistSentimentCache(sentiment);
    }
    final sentimentEnd = DateTime.now();

    // ---- Provider engagement analytics (featured + top workers) ----
    final engagementStart = DateTime.now();
    final engagement = _computeEngagementStats(analyticsSnap, userById);
    final engagementEnd = DateTime.now();

    if (logTimings) {
      final elapsedMs = DateTime.now().difference(start).inMilliseconds;
      final queriesMs = queryEnd.difference(queryStart).inMilliseconds;
      final sentimentMs = sentimentEnd
          .difference(sentimentStart)
          .inMilliseconds;
      final engagementMs = engagementEnd
          .difference(engagementStart)
          .inMilliseconds;

      // ignore: avoid_print
      print('[AdminAnalytics] Firestore queries took $queriesMs ms');
      // ignore: avoid_print
      print('[AdminAnalytics] Sentiment computation took $sentimentMs ms');
      // ignore: avoid_print
      print('[AdminAnalytics] Engagement aggregation took $engagementMs ms');
      // ignore: avoid_print
      print('[AdminAnalytics] loadAnalytics completed in $elapsedMs ms');
    }

    final result = AdminAnalyticsData(
      bookingRangeDays: effectiveBookingRangeDays,
      totalUsers: totalUsers,
      customerCount: customerCount,
      providerCount: providerCount,
      adminCount: adminCount,
      totalBookings: totalBookings,
      completedBookings: completedBookings,
      pendingBookings: pendingBookings,
      recentBookingsLast30Days: recentBookingsLast30Days,
      bookingsByStatus: bookingsByStatus,
      topCitiesByBookings: topCitiesByBookings,
      verificationCounts: verificationCounts,
      signupsLast7DaysByDay: signupsLast7DaysByDay,
      signupsLast30DaysByDay: signupsLast30DaysByDay,
      topProviders: topProviders,
      avgSentiment: sentiment.avgScore,
      positiveReviewCount: sentiment.positiveCount,
      neutralReviewCount: sentiment.neutralCount,
      negativeReviewCount: sentiment.negativeCount,
      engagementStats: engagement,
    );

    _analyticsCache = result;
    _analyticsCacheAt = DateTime.now();
    await _persistAnalyticsCache(result);

    return result;
  }

  /// Live analytics stream: periodically re-computes analytics so the
  /// admin dashboard can auto-update while it is open.
  static Stream<AdminAnalyticsData> analyticsStream({
    Duration refreshInterval = const Duration(minutes: 15),
    int? bookingRangeDays = 30,
  }) async* {
    // Emit a cached snapshot quickly (if available), then refresh.
    try {
      yield await loadAnalytics(
        useCachedAnalytics: true,
        bookingRangeDays: bookingRangeDays,
      );
    } catch (_) {}

    yield await loadAnalytics(
      logTimings: true,
      bookingRangeDays: bookingRangeDays,
    );

    // Then keep refreshing on a fixed interval.
    yield* Stream.periodic(refreshInterval).asyncMap(
      (_) =>
          loadAnalytics(logTimings: true, bookingRangeDays: bookingRangeDays),
    );
  }

  static Future<_SentimentStats> _computeSentimentStats(
    List<ReviewModel> reviews,
  ) async {
    final SentimentStats s = await SentimentUtils.computeWithAi(reviews);
    return _SentimentStats(
      avgScore: s.avgScore,
      positiveCount: s.positiveCount,
      neutralCount: s.neutralCount,
      negativeCount: s.negativeCount,
    );
  }

  static EngagementStats _computeEngagementStats(
    QuerySnapshot<Map<String, dynamic>> analyticsSnap,
    Map<String, AppUser> userById,
  ) {
    int totalFeaturedImpressions = 0;
    int totalFeaturedClicks = 0;
    int totalTopWorkersImpressions = 0;

    final Map<String, _EngagementProviderAgg> providerAgg =
        <String, _EngagementProviderAgg>{};

    for (final doc in analyticsSnap.docs) {
      final data = doc.data();
      final type = data['type'] as String? ?? '';

      if (type == 'featured_impression') {
        final ids =
            (data['providerIds'] as List?)?.cast<String>() ?? const <String>[];
        if (ids.isEmpty) continue;
        totalFeaturedImpressions += ids.length;
        for (final id in ids) {
          providerAgg
              .putIfAbsent(id, () => _EngagementProviderAgg())
              .impressions++;
        }
      } else if (type == 'featured_click') {
        final id = data['providerId'] as String?;
        if (id == null || id.isEmpty) continue;
        totalFeaturedClicks++;
        providerAgg.putIfAbsent(id, () => _EngagementProviderAgg()).clicks++;
      } else if (type == 'top_workers_impression') {
        final ids =
            (data['providerIds'] as List?)?.cast<String>() ?? const <String>[];
        if (ids.isEmpty) continue;
        totalTopWorkersImpressions += ids.length;
        for (final id in ids) {
          providerAgg
              .putIfAbsent(id, () => _EngagementProviderAgg())
              .impressions++;
        }
      }
    }

    final providers = <EngagementProvider>[];
    final entries = providerAgg.entries.toList()
      ..sort((a, b) => b.value.clicks.compareTo(a.value.clicks));

    final top = entries.length > 5 ? entries.sublist(0, 5) : entries;
    for (final e in top) {
      final user = userById[e.key];
      final rawName = user?.name?.trim();
      final name = (rawName != null && rawName.isNotEmpty)
          ? rawName
          : 'Provider';
      providers.add(
        EngagementProvider(
          id: e.key,
          name: name,
          clicks: e.value.clicks,
          impressions: e.value.impressions,
        ),
      );
    }

    return EngagementStats(
      totalFeaturedImpressions: totalFeaturedImpressions,
      totalFeaturedClicks: totalFeaturedClicks,
      totalTopWorkersImpressions: totalTopWorkersImpressions,
      topProvidersByClicks: providers,
    );
  }
}

class AdminAnalyticsData {
  final int? bookingRangeDays;
  final int totalUsers;
  final int customerCount;
  final int providerCount;
  final int adminCount;

  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final int recentBookingsLast30Days;
  final Map<String, int> bookingsByStatus;
  final List<CityCount> topCitiesByBookings;
  final Map<String, int> verificationCounts;
  final Map<String, int> signupsLast7DaysByDay;
  final Map<String, int> signupsLast30DaysByDay;
  final List<TopProvider> topProviders;

  // Sentiment over all customer reviews
  final double avgSentiment; // -1.0 (very negative) .. +1.0 (very positive)
  final int positiveReviewCount;
  final int neutralReviewCount;
  final int negativeReviewCount;

  // Engagement over featured providers and top workers sections
  final EngagementStats engagementStats;

  const AdminAnalyticsData({
    required this.bookingRangeDays,
    required this.totalUsers,
    required this.customerCount,
    required this.providerCount,
    required this.adminCount,
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.recentBookingsLast30Days,
    required this.bookingsByStatus,
    required this.topCitiesByBookings,
    required this.verificationCounts,
    required this.signupsLast7DaysByDay,
    required this.signupsLast30DaysByDay,
    required this.topProviders,
    required this.avgSentiment,
    required this.positiveReviewCount,
    required this.neutralReviewCount,
    required this.negativeReviewCount,
    required this.engagementStats,
  });
}

class CityCount {
  final String city;
  final int count;

  const CityCount({required this.city, required this.count});
}

class TopProvider {
  final String id;
  final String name;
  final int completedBookings;

  const TopProvider({
    required this.id,
    required this.name,
    required this.completedBookings,
  });
}

class EngagementStats {
  final int totalFeaturedImpressions;
  final int totalFeaturedClicks;
  final int totalTopWorkersImpressions;
  final List<EngagementProvider> topProvidersByClicks;

  const EngagementStats({
    required this.totalFeaturedImpressions,
    required this.totalFeaturedClicks,
    required this.totalTopWorkersImpressions,
    required this.topProvidersByClicks,
  });
}

class EngagementProvider {
  final String id;
  final String name;
  final int clicks;
  final int impressions;

  const EngagementProvider({
    required this.id,
    required this.name,
    required this.clicks,
    required this.impressions,
  });
}

class _EngagementProviderAgg {
  int clicks = 0;
  int impressions = 0;
}

class _SentimentStats {
  final double avgScore;
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;

  const _SentimentStats({
    required this.avgScore,
    required this.positiveCount,
    required this.neutralCount,
    required this.negativeCount,
  });
}
