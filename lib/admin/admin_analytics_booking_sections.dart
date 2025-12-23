import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:assist/services/admin_analytics_service.dart';

import 'package:assist/models/booking.dart';
import 'package:assist/admin/admin_analytics_widgets.dart';

String _bookingRangeLabel(int? days) {
  if (days == null) {
    return 'All time';
  }
  return 'Last $days days';
}

class BookingsSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const BookingsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final rangeLabel = _bookingRangeLabel(data.bookingRangeDays);

    final maxBookings = data.totalBookings == 0 ? 1 : data.totalBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bookings ($rangeLabel)',
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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                  Text('Total bookings', style: theme.textTheme.bodyMedium),
                  Text(
                    data.totalBookings.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnalyticsBookingsBar(
                label: 'Completed',
                value: data.completedBookings,
                max: maxBookings,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              AnalyticsBookingsBar(
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
                      color: onSurface.withValues(alpha: 0.8),
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
}

class BookingsByStatusSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const BookingsByStatusSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.bookingsByStatus.isEmpty || data.totalBookings == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final rangeLabel = _bookingRangeLabel(data.bookingRangeDays);

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
          'Bookings by status ($rangeLabel)',
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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                            value: (data.bookingsByStatus[status] ?? 0)
                                .toDouble(),
                            title: '',
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
                      AnalyticsLegendItem(
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
}

class BookingsByCitySection extends StatelessWidget {
  final AdminAnalyticsData data;

  const BookingsByCitySection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.topCitiesByBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final rangeLabel = _bookingRangeLabel(data.bookingRangeDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Bookings by city (top ${data.topCitiesByBookings.length}) ($rangeLabel)',
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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                  for (int i = 0; i < data.topCitiesByBookings.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data.topCitiesByBookings[i].count.toDouble(),
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                          meta: meta,
                          space: 8,
                          child: Text(city, style: theme.textTheme.bodySmall),
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

class VerificationSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const VerificationSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                            value: (data.verificationCounts[key] ?? 0)
                                .toDouble(),
                            title: '',
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
                      AnalyticsLegendItem(
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
}

class TopProvidersSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const TopProvidersSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.topProviders.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final rangeLabel = _bookingRangeLabel(data.bookingRangeDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Top providers (by completed bookings) ($rangeLabel)',
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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                          meta: meta,
                          space: 8,
                          child: Text(name, style: theme.textTheme.bodySmall),
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

class EngagementSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const EngagementSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
}
