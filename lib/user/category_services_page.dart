// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/services/service_catalog_service.dart';
import 'package:flutter_application_1/services/worker_ranking_service.dart';

import 'service_detail_page.dart';

class CategoryServicesPage extends StatelessWidget {
  final CategoryModel category;

  const CategoryServicesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(category.name),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<ServiceModel>>(
        stream:
            ServiceCatalogService.instance.watchServicesForCategory(category.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load services.'),
            );
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return const Center(
              child: Text('No services available in this category.'),
            );
          }

          return FutureBuilder<List<_ServiceWithDistance>>(
            future: _loadServicesWithDistance(services),
            builder: (context, distanceSnap) {
              if (distanceSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (distanceSnap.hasError) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final s = services[index];
                    return _CategoryServiceTile(service: s);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: services.length,
                );
              }

              final items = distanceSnap.data ?? [];

              if (items.isEmpty) {
                return const Center(
                  child: Text('No services available near you.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _CategoryServiceTile(
                    service: item.service,
                    distanceKm: item.distanceKm,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: items.length,
              );
            },
          );
        },
      ),
    );
  }
}

class _ServiceWithDistance {
  final ServiceModel service;
  final AppUser? provider;
  final double? distanceKm;

  _ServiceWithDistance({
    required this.service,
    required this.provider,
    required this.distanceKm,
  });
}

class _CategoryServiceTile extends StatelessWidget {
  final ServiceModel service;
  final double? distanceKm;

  const _CategoryServiceTile({required this.service, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final s = service;
    String? distanceLabel;
    if (distanceKm != null) {
      final d = distanceKm!;
      if (d < 1.0) {
        distanceLabel = '${(d * 1000).round()} m away';
      } else {
        distanceLabel = '${d.toStringAsFixed(1)} km away';
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceDetailPage(service: s),
            ),
          );
        },
        child: Row(
          children: [
            const Icon(Icons.cleaning_services_rounded,
                color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.description ??
                        'Starting from PKR ${s.basePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${s.basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    distanceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<_ServiceWithDistance>> _loadServicesWithDistance(
  List<ServiceModel> services,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  double? userLat;
  double? userLng;

  if (currentUser != null) {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final userData = userDoc.data();
    if (userData != null) {
      userLat = (userData['locationLat'] as num?)?.toDouble();
      userLng = (userData['locationLng'] as num?)?.toDouble();
    }
  }

  final providerIds = services
      .map((s) => s.providerId)
      .where((id) => id != null && id.isNotEmpty)
      .cast<String>()
      .toSet();

  Map<String, AppUser> providersById = {};

  if (providerIds.isNotEmpty) {
    final providerSnap = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: providerIds.toList())
        .get();

    providersById = {
      for (final doc in providerSnap.docs)
        doc.id: AppUser.fromMap(doc.id, doc.data())
    };
  }

  final result = <_ServiceWithDistance>[];

  for (final s in services) {
    final provider =
        s.providerId != null ? providersById[s.providerId!] : null;

    double? distanceKm;
    if (userLat != null &&
        userLng != null &&
        provider?.locationLat != null &&
        provider?.locationLng != null) {
      distanceKm = WorkerRankingService.haversineKm(
        userLat,
        userLng,
        provider!.locationLat!,
        provider.locationLng!,
      );
    }

    result.add(
      _ServiceWithDistance(
        service: s,
        provider: provider,
        distanceKm: distanceKm,
      ),
    );
  }

  final within5 = result
      .where((item) => item.distanceKm == null || item.distanceKm! <= 5.0)
      .toList();

  List<_ServiceWithDistance> filtered;

  if (within5.isNotEmpty) {
    filtered = within5;
  } else {
    filtered = result
        .where((item) => item.distanceKm == null || item.distanceKm! <= 15.0)
        .toList();
  }

  filtered.sort((a, b) {
    final da = a.distanceKm ?? double.infinity;
    final db = b.distanceKm ?? double.infinity;
    return da.compareTo(db);
  });

  return filtered;
}
