import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final int rating; // 1-5
  final String? comment;
  final DateTime? createdAt;

  final int? qPunctuality; // 1-5
  final int? qQuality; // 1-5
  final int? qCommunication; // 1-5
  final int? qProfessionalism; // 1-5
  final bool? wouldRecommend;

  final bool? hadDispute;
  final int? completionTimeMinutes;
  final int? expectedDurationMinutes;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.qPunctuality,
    this.qQuality,
    this.qCommunication,
    this.qProfessionalism,
    this.wouldRecommend,
    this.hadDispute,
    this.completionTimeMinutes,
    this.expectedDurationMinutes,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    return ReviewModel(
      id: id,
      bookingId: data['bookingId'] as String,
      customerId: data['customerId'] as String,
      providerId: data['providerId'] as String,
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      qPunctuality: data['qPunctuality'] as int?,
      qQuality: data['qQuality'] as int?,
      qCommunication: data['qCommunication'] as int?,
      qProfessionalism: data['qProfessionalism'] as int?,
      wouldRecommend: data['wouldRecommend'] as bool?,
      hadDispute: data['hadDispute'] as bool?,
      completionTimeMinutes: data['completionTimeMinutes'] as int?,
      expectedDurationMinutes: data['expectedDurationMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'providerId': providerId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'qPunctuality': qPunctuality,
      'qQuality': qQuality,
      'qCommunication': qCommunication,
      'qProfessionalism': qProfessionalism,
      'wouldRecommend': wouldRecommend,
      'hadDispute': hadDispute,
      'completionTimeMinutes': completionTimeMinutes,
      'expectedDurationMinutes': expectedDurationMinutes,
    };
  }
}
