import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String? categoryId;
  final String? description;
  final num basePrice;
  final int? durationEstimateMinutes;
  final List<String> images;
  final bool isActive;
  final DateTime? createdAt;
  final String? providerId;

  const ServiceModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.basePrice = 0,
    this.durationEstimateMinutes,
    this.images = const [],
    this.isActive = true,
    this.createdAt,
    this.providerId,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String?,
      description: data['description'] as String?,
      basePrice: (data['basePrice'] as num?) ?? 0,
      durationEstimateMinutes: data['durationEstimate'] as int?,
      images: (data['images'] as List?)?.cast<String>() ?? const [],
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      providerId: data['providerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'basePrice': basePrice,
      'durationEstimate': durationEstimateMinutes,
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'providerId': providerId,
    };
  }
}
