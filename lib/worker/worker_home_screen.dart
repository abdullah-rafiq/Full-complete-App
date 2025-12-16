import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/controllers/current_user_controller.dart';
import 'package:flutter_application_1/common/profile_page.dart';
import 'package:flutter_application_1/localized_strings.dart';
import 'worker_jobs_page.dart';
import 'worker_earnings_page.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkerVerificationBanner(),
            const SizedBox(height: 25),

            Text(
              L10n.workerTodayOverviewTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 4),
            Text(
              L10n.workerTodayOverviewSubtitle(),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            const _WorkerDemandHint(),
            const SizedBox(height: 20),

            SizedBox(
              height: 170,
              child: PageView(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkerJobsPage(),
                        ),
                      );
                    },
                    child: _buildIncomingCard(context),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkerEarningsPage(),
                        ),
                      );
                    },
                    child: _buildMyJobsCard(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF29B6F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF29B6F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.workerIncomingRequestsTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  L10n.workerIncomingRequestsSubtitle(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.workerMyJobsEarningsTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  L10n.workerMyJobsEarningsSubtitle(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerDemandHint extends StatelessWidget {
  const _WorkerDemandHint();

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      return const SizedBox.shrink();
    }

    final bookingsQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: current.uid)
        .where('status', isEqualTo: BookingStatus.completed);

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: bookingsQuery.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final bookings = docs
            .map((d) => BookingModel.fromMap(d.id, d.data()))
            .toList();

        final hint = _computeDemandHint(bookings);
        if (hint == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.access_time,
              size: 18,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _computeDemandHint(List<BookingModel> bookings) {
    if (bookings.isEmpty) return null;

    final Map<int, int> dayCounts = <int, int>{};
    final Map<String, int> bandCounts = <String, int>{};

    for (final b in bookings) {
      DateTime? dt = b.scheduledTime ?? b.createdAt;
      if (dt == null) continue;
      dt = dt.toLocal();

      final day = dt.weekday; // 1=Mon..7=Sun
      final hour = dt.hour;

      dayCounts[day] = (dayCounts[day] ?? 0) + 1;

      final String band;
      if (hour >= 6 && hour < 12) {
        band = 'Morning';
      } else if (hour >= 12 && hour < 17) {
        band = 'Afternoon';
      } else if (hour >= 17 && hour < 21) {
        band = 'Evening';
      } else {
        band = 'Night';
      }
      bandCounts[band] = (bandCounts[band] ?? 0) + 1;
    }

    if (dayCounts.isEmpty || bandCounts.isEmpty) return null;

    final sortedDays = dayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDayKeys = sortedDays.take(2).map((e) => e.key).toList();

    final topBandEntry = bandCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    String dayLabel;
    if (topDayKeys.length == 1) {
      dayLabel = _weekdayName(topDayKeys[0]);
    } else {
      dayLabel = '${_weekdayName(topDayKeys[0])} & ${_weekdayName(topDayKeys[1])}';
    }

    final band = topBandEntry.key;
    final bandRange = _bandRangeLabel(band);

    return 'Most of your completed jobs are on $dayLabel during $band ($bandRange).';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
      default:
        return 'Sun';
    }
  }

  String _bandRangeLabel(String band) {
    switch (band) {
      case 'Morning':
        return '6am–12pm';
      case 'Afternoon':
        return '12pm–5pm';
      case 'Evening':
        return '5pm–9pm';
      case 'Night':
      default:
        return '9pm–6am';
    }
  }
}

class _WorkerVerificationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<AppUser?>(
      stream: CurrentUserController.watchCurrentUser(),

      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isDocApproved = user?.verificationStatus == 'approved';
        if (user == null || user.role != UserRole.provider || isDocApproved) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final Color bgColor =
            isDark ? theme.colorScheme.surfaceVariant : const Color(0xFFFFF3E0);
        final Color iconColor =
            isDark ? Colors.amberAccent : const Color(0xFFF57C00);
        final Color titleColor =
            isDark ? Colors.white : const Color(0xFFBF360C);
        final Color descColor =
            isDark ? Colors.white70 : Colors.black87;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: iconColor,
              ),

              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete verification to take jobs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'Upload CNIC, live picture, and shop/tools photo so you can start accepting and completing jobs.',
                      style: TextStyle(
                        fontSize: 12,
                        color: descColor,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                        },
                        child: const Text('Go to profile to verify'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}