import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:assist/services/admin_analytics_service.dart';
import 'package:assist/admin/admin_analytics_widgets.dart';

class UserStatsGridSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const UserStatsGridSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
            AnalyticsStatCard(
              title: 'Total users',
              value: data.totalUsers.toString(),
              icon: Icons.people_outline,
              color: Colors.blueAccent,
              subtitle: 'All registered users',
            ),
            AnalyticsStatCard(
              title: 'Customers',
              value: data.customerCount.toString(),
              icon: Icons.person_outline,
              color: Colors.green,
              percentage: hasUsers
                  ? data.customerCount / data.totalUsers
                  : null,
              subtitle: hasUsers ? 'Of all users' : null,
            ),
            AnalyticsStatCard(
              title: 'Providers',
              value: data.providerCount.toString(),
              icon: Icons.handyman_outlined,
              color: Colors.orange,
              percentage: hasUsers
                  ? data.providerCount / data.totalUsers
                  : null,
              subtitle: hasUsers ? 'Of all users' : null,
            ),
            AnalyticsStatCard(
              title: 'Admins',
              value: data.adminCount.toString(),
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.purple,
              percentage: hasUsers ? data.adminCount / data.totalUsers : null,
              subtitle: hasUsers ? 'Of all users' : null,
            ),
          ],
        ),
      ],
    );
  }
}

class ReviewSentimentSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const ReviewSentimentSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total =
        data.positiveReviewCount +
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

    final avgPercent = ((data.avgSentiment + 1.0) / 2.0 * 100).clamp(
      0.0,
      100.0,
    );

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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                          title: '',
                        ),
                      if (data.neutralReviewCount > 0)
                        PieChartSectionData(
                          color: Colors.blueGrey,
                          value: data.neutralReviewCount.toDouble(),
                          title: '',
                        ),
                      if (data.negativeReviewCount > 0)
                        PieChartSectionData(
                          color: Colors.redAccent,
                          value: data.negativeReviewCount.toDouble(),
                          title: '',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  AnalyticsLegendItem(color: Colors.green, label: 'Positive'),
                  AnalyticsLegendItem(color: Colors.blueGrey, label: 'Neutral'),
                  AnalyticsLegendItem(
                    color: Colors.redAccent,
                    label: 'Negative',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(sentimentLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                'Average sentiment score: '
                '${avgPercent.toStringAsFixed(0)} / 100',
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
}

class UserDistributionSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const UserDistributionSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                      if (data.customerCount > 0)
                        PieChartSectionData(
                          color: Colors.green,
                          value: data.customerCount.toDouble(),
                          title: '',
                        ),
                      if (data.providerCount > 0)
                        PieChartSectionData(
                          color: Colors.orange,
                          value: data.providerCount.toDouble(),
                          title: '',
                        ),
                      if (data.adminCount > 0)
                        PieChartSectionData(
                          color: Colors.purple,
                          value: data.adminCount.toDouble(),
                          title: '',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  AnalyticsLegendItem(color: Colors.green, label: 'Customers'),
                  AnalyticsLegendItem(color: Colors.orange, label: 'Providers'),
                  AnalyticsLegendItem(color: Colors.purple, label: 'Admins'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SignupsTrendSection extends StatelessWidget {
  final AdminAnalyticsData data;

  const SignupsTrendSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.signupsLast7DaysByDay.isEmpty &&
        data.signupsLast30DaysByDay.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final last7Total = data.signupsLast7DaysByDay.values.fold<int>(
      0,
      (prev, v) => prev + v,
    );
    final last30Total = data.signupsLast30DaysByDay.values.fold<int>(
      0,
      (prev, v) => prev + v,
    );

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
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= 7) {
                              return const SizedBox.shrink();
                            }
                            final labels = [
                              '6d',
                              '5d ',
                              '4d ',
                              '3d ',
                              '2d',
                              'Y',
                              'T',
                            ];
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                labels[index],
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
              const Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: '6d = 6 days ago',
                  ),
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: '5d = 5 days ago',
                  ),
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: '4d = 4 days ago',
                  ),
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: '3d = 3 days ago',
                  ),
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: '2d = 2 days ago',
                  ),
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: '1d = 1 day ago',
                  ),
                  AnalyticsLegendItem(
                    color: Colors.teal,
                    label: 'Y = Yesterday',
                  ),
                  AnalyticsLegendItem(color: Colors.teal, label: 'T = Today'),
                ],
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
}
