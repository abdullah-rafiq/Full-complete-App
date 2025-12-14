import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/review.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  Future<_AdminAnalyticsData> _loadAnalytics() async {
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

    final usersCol = db.collection('users');
    final bookingsCol = db.collection('bookings');
    final reviewsCol = db.collection('reviews');
    final analyticsCol = db.collection('analytics_events');

    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      usersCol.get(),
      bookingsCol.get(),
      reviewsCol.get(),
      analyticsCol.get(),
    ]);

    final usersSnap = results[0];
    final bookingsSnap = results[1];
    final reviewsSnap = results[2];
    final analyticsSnap = results[3];

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
          signupsLast7DaysByDay[key] =
              (signupsLast7DaysByDay[key] ?? 0) + 1;
        }

        if (!day.isBefore(last30Start) && !day.isAfter(today)) {
          signupsLast30DaysByDay[key] =
              (signupsLast30DaysByDay[key] ?? 0) + 1;
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
    final completedBookings =
        bookingsByStatus[BookingStatus.completed] ?? 0;
    final pendingBookings =
        bookingsByStatus[BookingStatus.requested] ?? 0;

    // Top cities by bookings (max 5)
    final List<_CityCount> topCitiesByBookings = cityCounts.entries
        .map((e) => _CityCount(city: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    if (topCitiesByBookings.length > 5) {
      topCitiesByBookings.removeRange(5, topCitiesByBookings.length);
    }

    // Top providers by completed bookings (max 5)
    final List<_TopProvider> topProviders = providerCompletedCounts.entries
        .map((e) {
          final user = userById[e.key];
          final rawName = user?.name?.trim();
          final name = (rawName != null && rawName.isNotEmpty)
              ? rawName
              : 'Provider';
          return _TopProvider(
            id: e.key,
            name: name,
            completedBookings: e.value,
          );
        })
        .toList()
      ..sort((a, b) => b.completedBookings.compareTo(a.completedBookings));
    if (topProviders.length > 5) {
      topProviders.removeRange(5, topProviders.length);
    }

    final reviews = reviewsSnap.docs
        .map((d) => ReviewModel.fromMap(d.id, d.data()))
        .toList();
    final sentiment = _computeSentimentStats(reviews);

    // ---- Provider engagement analytics (featured + top workers) ----
    final engagement = _computeEngagementStats(analyticsSnap, userById);

    return _AdminAnalyticsData(
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
  }

  Widget _buildEngagementSection(
      BuildContext context, _AdminAnalyticsData data) {
    final stats = data.engagementStats;

    if (stats.totalFeaturedImpressions == 0 &&
        stats.totalFeaturedClicks == 0 &&
        stats.totalTopWorkersImpressions == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final double featuredCtr = stats.totalFeaturedImpressions > 0
        ? (stats.totalFeaturedClicks / stats.totalFeaturedImpressions) * 100.0
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Provider engagement (featured & top workers)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Featured providers',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Impressions: ${stats.totalFeaturedImpressions}, '
                'Clicks: ${stats.totalFeaturedClicks}, '
                'CTR: ${featuredCtr.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Top workers section',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Impressions: ${stats.totalTopWorkersImpressions}',
                style: theme.textTheme.bodySmall,
              ),
              if (stats.topProvidersByClicks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Most clicked providers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Column(
                  children: stats.topProvidersByClicks.map((p) {
                    final ctr = p.impressions > 0
                        ? (p.clicks / p.impressions) * 100.0
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${p.clicks} clicks / ${p.impressions} impressions (${ctr.toStringAsFixed(0)}%)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 4,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<_AdminAnalyticsData>(
        future: _loadAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading analytics: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No analytics data available.'));
          }

          final onSurface = theme.colorScheme.onSurface;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildUserStatsGrid(context, data),
                _buildUserDistributionSection(context, data),
                const SizedBox(height: 24),
                _buildBookingsSection(context, data),
                _buildBookingsByStatusSection(context, data),
                _buildBookingsByCitySection(context, data),
                _buildReviewSentimentSection(context, data),
                _buildEngagementSection(context, data),
                _buildSignupsTrendSection(context, data),
                _buildVerificationSection(context, data),
                _buildTopProvidersSection(context, data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserStatsGrid(BuildContext context, _AdminAnalyticsData data) {
    final hasUsers = data.totalUsers > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total users',
              value: data.totalUsers.toString(),
              icon: Icons.people_outline,
              color: Colors.blueAccent,
              subtitle: 'All registered users',
            ),
            _StatCard(
              title: 'Customers',
              value: data.customerCount.toString(),
              icon: Icons.person_outline,
              color: Colors.green,
              percentage:
                  hasUsers ? data.customerCount / data.totalUsers : null,
              subtitle: hasUsers ? 'Of all users' : null,
            ),
            _StatCard(
              title: 'Providers',
              value: data.providerCount.toString(),
              icon: Icons.handyman_outlined,
              color: Colors.orange,
              percentage:
                  hasUsers ? data.providerCount / data.totalUsers : null,
              subtitle: hasUsers ? 'Of all users' : null,
            ),
            _StatCard(
              title: 'Admins',
              value: data.adminCount.toString(),
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.purple,
              percentage:
                  hasUsers ? data.adminCount / data.totalUsers : null,
              subtitle: hasUsers ? 'Of all users' : null,
            ),
          ],
        ),
      ],
    );
  }

  /// Compute sentiment statistics over all customer review comments and ratings.
  /// Returns average sentiment in [-1, 1] and counts for positive/neutral/negative.
  _SentimentStats _computeSentimentStats(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const _SentimentStats(
        avgScore: 0.0,
        positiveCount: 0,
        neutralCount: 0,
        negativeCount: 0,
      );
    }

    // Simple but non-trivial lexicon-based sentiment over comments,
    // blended with star rating and questionnaire answers.
    const positiveWords = [
      'good',
      'great',
      'excellent',
      'amazing',
      'perfect',
      'nice',
      'fast',
      'friendly',
      'professional',
      'clean',
      'satisfied',
      'recommend',
      'helpful',
    ];
    const negativeWords = [
      'bad',
      'poor',
      'terrible',
      'awful',
      'late',
      'rude',
      'dirty',
      'slow',
      'unprofessional',
      'disappointed',
      'refund',
      'complaint',
    ];

    double total = 0.0;
    int pos = 0;
    int neu = 0;
    int neg = 0;

    for (final r in reviews) {
      // Start from normalized rating (1-5 -> -1..+1)
      final rating = r.rating.clamp(1, 5);
      double score = ((rating - 3) / 2).clamp(-1.0, 1.0).toDouble();

      // Questionnaire average (if present) also in -1..+1
      final qVals = <int?>[
        r.qPunctuality,
        r.qQuality,
        r.qCommunication,
        r.qProfessionalism,
      ].where((v) => v != null).cast<int>().toList();

      if (qVals.isNotEmpty) {
        final avgQ = qVals.reduce((a, b) => a + b) / qVals.length;
        final qScore = ((avgQ - 3.0) / 2.0).clamp(-1.0, 1.0);
        // Blend questionnaire with main rating
        score = (score * 0.7) + (qScore * 0.3);
      }

      // Text sentiment from comment using simple lexicon counts
      final comment = r.comment?.toLowerCase() ?? '';
      if (comment.isNotEmpty) {
        int posHits = 0;
        int negHits = 0;

        for (final w in positiveWords) {
          if (comment.contains(w)) posHits++;
        }
        for (final w in negativeWords) {
          if (comment.contains(w)) negHits++;
        }

        if (posHits > 0 || negHits > 0) {
          final textScore = ((posHits - negHits) / (posHits + negHits))
              .clamp(-1.0, 1.0);
          // Blend text with numeric rating: keep rating primary
          score = (score * 0.6) + (textScore * 0.4);
        }
      }

      // Additional adjustment: wouldRecommend and disputes
      if (r.wouldRecommend == true) {
        score += 0.1;
      } else if (r.wouldRecommend == false) {
        score -= 0.1;
      }

      if (r.hadDispute == true) {
        score -= 0.2;
      }

      // Clamp final score
      score = score.clamp(-1.0, 1.0);

      total += score;

      if (score > 0.2) {
        pos++;
      } else if (score < -0.2) {
        neg++;
      } else {
        neu++;
      }
    }

    final avg = (total / reviews.length).clamp(-1.0, 1.0);
    return _SentimentStats(
      avgScore: avg,
      positiveCount: pos,
      neutralCount: neu,
      negativeCount: neg,
    );
  }

  _EngagementStats _computeEngagementStats(
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
        final ids = (data['providerIds'] as List?)?.cast<String>() ??
            const <String>[];
        if (ids.isEmpty) continue;
        totalFeaturedImpressions += ids.length;
        for (final id in ids) {
          providerAgg.putIfAbsent(id, () => _EngagementProviderAgg()).
              impressions++;
        }
      } else if (type == 'featured_click') {
        final id = data['providerId'] as String?;
        if (id == null || id.isEmpty) continue;
        totalFeaturedClicks++;
        providerAgg.putIfAbsent(id, () => _EngagementProviderAgg()).clicks++;
      } else if (type == 'top_workers_impression') {
        final ids = (data['providerIds'] as List?)?.cast<String>() ??
            const <String>[];
        if (ids.isEmpty) continue;
        totalTopWorkersImpressions += ids.length;
        for (final id in ids) {
          providerAgg.putIfAbsent(id, () => _EngagementProviderAgg()).
              impressions++;
        }
      }
    }

    final providers = <_EngagementProvider>[];
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
        _EngagementProvider(
          id: e.key,
          name: name,
          clicks: e.value.clicks,
          impressions: e.value.impressions,
        ),
      );
    }

    return _EngagementStats(
      totalFeaturedImpressions: totalFeaturedImpressions,
      totalFeaturedClicks: totalFeaturedClicks,
      totalTopWorkersImpressions: totalTopWorkersImpressions,
      topProvidersByClicks: providers,
    );
  }

  Widget _buildReviewSentimentSection(
      BuildContext context, _AdminAnalyticsData data) {
    final total = data.positiveReviewCount +
        data.neutralReviewCount +
        data.negativeReviewCount;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    String sentimentLabel;
    if (data.avgSentiment > 0.25) {
      sentimentLabel = 'Overall sentiment: Positive';
    } else if (data.avgSentiment < -0.25) {
      sentimentLabel = 'Overall sentiment: Negative';
    } else {
      sentimentLabel = 'Overall sentiment: Neutral';
    }

    final avgPercent = ((data.avgSentiment + 1.0) / 2.0 * 100).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Customer review sentiment',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      if (data.positiveReviewCount > 0)
                        PieChartSectionData(
                          color: Colors.green,
                          value: data.positiveReviewCount.toDouble(),
                          title: 'Positive',
                          titleStyle:
                              theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (data.neutralReviewCount > 0)
                        PieChartSectionData(
                          color: Colors.blueGrey,
                          value: data.neutralReviewCount.toDouble(),
                          title: 'Neutral',
                          titleStyle:
                              theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (data.negativeReviewCount > 0)
                        PieChartSectionData(
                          color: Colors.redAccent,
                          value: data.negativeReviewCount.toDouble(),
                          title: 'Negative',
                          titleStyle:
                              theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const [
                  _LegendItem(color: Colors.green, label: 'Positive'),
                  _LegendItem(color: Colors.blueGrey, label: 'Neutral'),
                  _LegendItem(color: Colors.redAccent, label: 'Negative'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sentimentLabel,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Average sentiment score: ${avgPercent.toStringAsFixed(0)} / 100',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Based on $total review(s)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserDistributionSection(
      BuildContext context, _AdminAnalyticsData data) {
    if (data.totalUsers == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'User distribution',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      if (data.customerCount > 0)
                        PieChartSectionData(
                          color: Colors.green,
                          value: data.customerCount.toDouble(),
                          title: 'Customers',
                          titleStyle:
                              theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (data.providerCount > 0)
                        PieChartSectionData(
                          color: Colors.orange,
                          value: data.providerCount.toDouble(),
                          title: 'Providers',
                          titleStyle:
                              theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (data.adminCount > 0)
                        PieChartSectionData(
                          color: Colors.purple,
                          value: data.adminCount.toDouble(),
                          title: 'Admins',
                          titleStyle:
                              theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: const [
                  _LegendItem(color: Colors.green, label: 'Customers'),
                  _LegendItem(color: Colors.orange, label: 'Providers'),
                  _LegendItem(color: Colors.purple, label: 'Admins'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsSection(BuildContext context, _AdminAnalyticsData data) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final maxBookings =
        data.totalBookings == 0 ? 1 : data.totalBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bookings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total bookings',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    data.totalBookings.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BookingsBar(
                label: 'Completed',
                value: data.completedBookings,
                max: maxBookings,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _BookingsBar(
                label: 'Pending',
                value: data.pendingBookings,
                max: maxBookings,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 30 days',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${data.recentBookingsLast30Days} bookings',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsByStatusSection(
      BuildContext context, _AdminAnalyticsData data) {
    if (data.bookingsByStatus.isEmpty || data.totalBookings == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    const statuses = <String>[
      BookingStatus.requested,
      BookingStatus.accepted,
      BookingStatus.onTheWay,
      BookingStatus.inProgress,
      BookingStatus.completed,
      BookingStatus.cancelled,
    ];

    Color colorForStatus(String status) {
      switch (status) {
        case BookingStatus.completed:
          return Colors.green;
        case BookingStatus.cancelled:
          return Colors.redAccent;
        case BookingStatus.accepted:
          return Colors.blue;
        case BookingStatus.onTheWay:
          return Colors.teal;
        case BookingStatus.inProgress:
          return Colors.deepPurple;
        case BookingStatus.requested:
        default:
          return Colors.orange;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Bookings by status',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (final status in statuses)
                        if ((data.bookingsByStatus[status] ?? 0) > 0)
                          PieChartSectionData(
                            color: colorForStatus(status),
                            value:
                                (data.bookingsByStatus[status] ?? 0).toDouble(),
                            title: status,
                            titleStyle:
                                theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final status in statuses)
                    if ((data.bookingsByStatus[status] ?? 0) > 0)
                      _LegendItem(
                        color: colorForStatus(status),
                        label: status,
                      ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsByCitySection(
      BuildContext context, _AdminAnalyticsData data) {
    if (data.topCitiesByBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Bookings by city (top ${data.topCitiesByBookings.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                barGroups: [
                  for (int i = 0;
                      i < data.topCitiesByBookings.length;
                      i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY:
                              data.topCitiesByBookings[i].count.toDouble(),
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= data.topCitiesByBookings.length) {
                          return const SizedBox.shrink();
                        }
                        final city = data.topCitiesByBookings[index].city;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            city,
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupsTrendSection(
      BuildContext context, _AdminAnalyticsData data) {
    if (data.signupsLast7DaysByDay.isEmpty &&
        data.signupsLast30DaysByDay.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final last7Total = data.signupsLast7DaysByDay.values
        .fold<int>(0, (prev, v) => prev + v);
    final last30Total = data.signupsLast30DaysByDay.values
        .fold<int>(0, (prev, v) => prev + v);

    // Build a simple 7-day trend line chart based on the last 7 days map.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Start = today.subtract(const Duration(days: 6));

    final List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      final day = last7Start.add(Duration(days: i));
      final key =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final count = data.signupsLast7DaysByDay[key] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'New signups',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= 7) {
                              return const SizedBox.shrink();
                            }
                            final day =
                                last7Start.add(Duration(days: index));
                            final label = '${day.day}/${day.month}';
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                label,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.teal,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Last 7 days: $last7Total signups',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Last 30 days: $last30Total signups',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSection(
      BuildContext context, _AdminAnalyticsData data) {
    if (data.verificationCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    const order = <String>['approved', 'pending', 'rejected', 'none'];

    Color colorForStatus(String status) {
      switch (status) {
        case 'approved':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'rejected':
          return Colors.redAccent;
        default:
          return Colors.blueGrey;
      }
    }

    String labelForStatus(String status) {
      switch (status) {
        case 'approved':
          return 'Approved';
        case 'pending':
          return 'Pending';
        case 'rejected':
          return 'Rejected';
        default:
          return 'Not submitted';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Provider verification',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (final key in order)
                        if ((data.verificationCounts[key] ?? 0) > 0)
                          PieChartSectionData(
                            color: colorForStatus(key),
                            value:
                                (data.verificationCounts[key] ?? 0).toDouble(),
                            title: labelForStatus(key),
                            titleStyle:
                                theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final key in order)
                    if ((data.verificationCounts[key] ?? 0) > 0)
                      _LegendItem(
                        color: colorForStatus(key),
                        label: labelForStatus(key),
                      ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopProvidersSection(
      BuildContext context, _AdminAnalyticsData data) {
    if (data.topProviders.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Top providers (by completed bookings)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                barGroups: [
                  for (int i = 0; i < data.topProviders.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data.topProviders[i].completedBookings
                              .toDouble(),
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.topProviders.length) {
                          return const SizedBox.shrink();
                        }
                        final name = data.topProviders[index].name;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            name,
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminAnalyticsData {
  final int totalUsers;
  final int customerCount;
  final int providerCount;
  final int adminCount;

  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final int recentBookingsLast30Days;
  final Map<String, int> bookingsByStatus;
  final List<_CityCount> topCitiesByBookings;
  final Map<String, int> verificationCounts;
  final Map<String, int> signupsLast7DaysByDay;
  final Map<String, int> signupsLast30DaysByDay;
  final List<_TopProvider> topProviders;

  // Sentiment over all customer reviews
  final double avgSentiment; // -1.0 (very negative) .. +1.0 (very positive)
  final int positiveReviewCount;
  final int neutralReviewCount;
  final int negativeReviewCount;

   // Engagement over featured providers and top workers sections
  final _EngagementStats engagementStats;

  const _AdminAnalyticsData({
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

class _CityCount {
  final String city;
  final int count;

  const _CityCount({required this.city, required this.count});
}

class _TopProvider {
  final String id;
  final String name;
  final int completedBookings;

  const _TopProvider({
    required this.id,
    required this.name,
    required this.completedBookings,
  });
}

class _EngagementStats {
  final int totalFeaturedImpressions;
  final int totalFeaturedClicks;
  final int totalTopWorkersImpressions;
  final List<_EngagementProvider> topProvidersByClicks;

  const _EngagementStats({
    required this.totalFeaturedImpressions,
    required this.totalFeaturedClicks,
    required this.totalTopWorkersImpressions,
    required this.topProvidersByClicks,
  });
}

class _EngagementProvider {
  final String id;
  final String name;
  final int clicks;
  final int impressions;

  const _EngagementProvider({
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? percentage;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.percentage,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                height: 36,
                width: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (percentage != null)
                      CircularProgressIndicator(
                        value: percentage!.clamp(0.0, 1.0).toDouble(),
                        strokeWidth: 3,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(
                        icon,
                        size: 18,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingsBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _BookingsBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (max <= 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            '0',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              value.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final ratio = value / max;
            final barWidth = constraints.maxWidth * ratio.clamp(0.0, 1.0);

            return Container(
              height: 6,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: barWidth,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
