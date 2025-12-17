import 'package:flutter/material.dart';

import 'package:flutter_application_1/services/admin_analytics_service.dart';
import 'package:flutter_application_1/admin/admin_analytics_user_sections.dart';
import 'package:flutter_application_1/admin/admin_analytics_booking_sections.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  int? _bookingRangeDays = 30;

  String _rangeLabel(int? days) {
    if (days == null) {
      return 'All time';
    }
    return 'Last $days days';
  }

  Widget _buildEngagementSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return EngagementSection(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), elevation: 4),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<AdminAnalyticsData>(
        stream: AdminAnalyticsService.analyticsStream(
          bookingRangeDays: _bookingRangeDays,
        ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Booking range',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<int?>(
                      value: _bookingRangeDays,
                      items: const [
                        DropdownMenuItem<int?>(
                          value: 30,
                          child: Text('Last 30 days'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 60,
                          child: Text('Last 60 days'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 90,
                          child: Text('Last 90 days'),
                        ),
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All time'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _bookingRangeDays = value;
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      _rangeLabel(_bookingRangeDays),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
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

  Widget _buildUserStatsGrid(BuildContext context, AdminAnalyticsData data) {
    return UserStatsGridSection(data: data);
  }

  Widget _buildReviewSentimentSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return ReviewSentimentSection(data: data);
  }

  Widget _buildUserDistributionSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return UserDistributionSection(data: data);
  }

  Widget _buildBookingsSection(BuildContext context, AdminAnalyticsData data) {
    return BookingsSection(data: data);
  }

  Widget _buildBookingsByStatusSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return BookingsByStatusSection(data: data);
  }

  Widget _buildBookingsByCitySection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return BookingsByCitySection(data: data);
  }

  Widget _buildSignupsTrendSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return SignupsTrendSection(data: data);
  }

  Widget _buildVerificationSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return VerificationSection(data: data);
  }

  Widget _buildTopProvidersSection(
    BuildContext context,
    AdminAnalyticsData data,
  ) {
    return TopProvidersSection(data: data);
  }
}
