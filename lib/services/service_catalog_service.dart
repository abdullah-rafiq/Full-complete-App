import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/service.dart';

class ServiceCatalogService {
  ServiceCatalogService._();

  static final ServiceCatalogService instance = ServiceCatalogService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, ServiceModel> _serviceCache = <String, ServiceModel>{};

  // Local, in-memory categories used for main page, category page and search.
  // Providers and services are still loaded from Firestore.
  static const List<CategoryModel> _localCategories = [
    CategoryModel(
      id: 'cleaner',
      name: 'Cleaner',
      iconUrl: 'assets/categories/cleaning.png',
    ),
    CategoryModel(
      id: 'ac_repair',
      name: 'AC Repair',
      iconUrl: 'assets/categories/Ac_Repair.png',
    ),
    CategoryModel(
      id: 'plumber',
      name: 'Plumber',
      iconUrl: 'assets/categories/plumber.png',
    ),
    CategoryModel(
      id: 'electrician',
      name: 'Electrician',
      iconUrl: 'assets/categories/electrician.png',
    ),
    CategoryModel(
      id: 'carpenter',
      name: 'Carpenter',
      iconUrl: 'assets/categories/carpentry.png',
    ),
    CategoryModel(
      id: 'painter',
      name: 'Painter',
      iconUrl: 'assets/categories/painter.png',
    ),
    CategoryModel(
      id: 'barber',
      name: 'Barber',
      iconUrl: 'assets/categories/barber.png',
    ),
  ];

  CollectionReference<Map<String, dynamic>> get _servicesCol =>
      _db.collection('services');

  Stream<List<CategoryModel>> watchCategories() {
    // Categories are local/static. Expose them as a one-shot stream so existing
    // StreamBuilder-based UIs keep working without hitting Firestore.
    final active = _localCategories
        .where((c) => c.isActive)
        .toList(growable: false);
    return Stream.value(active);
  }

  Stream<List<ServiceModel>> watchServicesForCategory(String categoryId) {
    return _servicesCol
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ServiceModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<ServiceModel?> getService(String id) async {
    final cached = _serviceCache[id];
    if (cached != null) return cached;

    final doc = await _servicesCol
        .doc(id)
        .get()
        .timeout(const Duration(seconds: 15));
    if (!doc.exists) return null;
    final service = ServiceModel.fromMap(doc.id, doc.data()!);
    _serviceCache[id] = service;
    return service;
  }

  /// Preload many services by ID in as few Firestore queries as possible.
  /// Uses the in-memory cache to avoid refetching services.
  Future<Map<String, ServiceModel?>> getServicesBatch(List<String> ids) async {
    final result = <String, ServiceModel?>{};
    if (ids.isEmpty) return result;

    final missing = <String>[];
    for (final id in ids) {
      final cached = _serviceCache[id];
      if (cached != null) {
        result[id] = cached;
      } else {
        missing.add(id);
      }
    }

    if (missing.isEmpty) return result;

    const chunkSize = 10;
    for (var i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.sublist(i, min(i + chunkSize, missing.length));
      final snap = await _servicesCol
          .where(FieldPath.documentId, whereIn: chunk)
          .get()
          .timeout(const Duration(seconds: 15));
      for (final doc in snap.docs) {
        final service = ServiceModel.fromMap(doc.id, doc.data());
        _serviceCache[doc.id] = service;
        result[doc.id] = service;
      }
    }

    // Any IDs that were not found in Firestore are recorded as null.
    for (final id in missing) {
      result.putIfAbsent(id, () => null);
    }

    return result;
  }
}
