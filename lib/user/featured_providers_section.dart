import 'package:flutter/material.dart';

import 'package:assist/models/service.dart';
import 'package:assist/user/service_detail_page.dart';
import 'package:assist/controllers/featured_providers_controller.dart';
import 'package:assist/services/analytics_service.dart';

const Color primaryLightBlue = Color(0xFF4FC3F7);
const Color primaryBlue = Color(0xFF29B6F6);
const Color primaryDarkBlue = Color(0xFF0288D1);

class FeaturedProvidersSection extends StatelessWidget {
  const FeaturedProvidersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: FutureBuilder<List<FeaturedProviderItem>>(
        future: FeaturedProvidersController.loadFeaturedProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load featured providers.',
                style: TextStyle(fontSize: 13),
              ),
            );
          }

          final providers = snapshot.data ?? [];
          if (providers.isEmpty) {
            return const Center(
              child: Text(
                'No featured providers available yet.',
                style: TextStyle(fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = providers[index];
              final user = item.user;
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final subtleTextColor = isDark
                  ? Colors.white70
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7);

              final name = (user.name?.trim().isNotEmpty ?? false)
                  ? user.name!.trim()
                  : 'Provider';

              final avatarImage =
                  (user.profileImageUrl != null &&
                      user.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(user.profileImageUrl!)
                  : const AssetImage('assets/profile.png') as ImageProvider;

              final rating = item.avgRating;
              final pricePerJob = (item.avgPrice ?? 0).toInt();
              final subtitle = user.city ?? 'Nearby service provider';

              return Container(
                width: 270,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 32, backgroundImage: avatarImage),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: isDark
                                      ? Colors.white
                                      : theme.textTheme.titleMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(color: subtleTextColor),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(color: subtleTextColor),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryLightBlue.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${item.completedJobs} jobs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white
                                            : primaryDarkBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PKR $pricePerJob/job',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : primaryDarkBlue,
                            fontSize: 15,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AnalyticsService.instance
                                .logEvent('featured_click', <String, dynamic>{
                                  'providerId': user.id,
                                  'avgPrice': item.avgPrice,
                                  'completedJobs': item.completedJobs,
                                  'avgRating': item.avgRating,
                                })
                                .catchError((_) {});

                            final service = ServiceModel(
                              id: 'featured_${user.id}',
                              name: 'Service with $name',
                              basePrice: item.avgPrice ?? 0,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServiceDetailPage(service: service),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryBlue,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Book Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (separatorContext, separatorIndex) =>
                const SizedBox(width: 14),
            itemCount: providers.length,
          );
        },
      ),
    );
  }
}
