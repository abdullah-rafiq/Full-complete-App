import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String bookingId;
  final String userId;
  final String? providerId;
  final num amount;
  final String method;
  final String? gatewayRef;
  final String status; // Success | Failed | Pending
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.providerId,
    required this.amount,
    required this.method,
    this.gatewayRef,
    this.status = 'Pending',
    this.createdAt,
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      bookingId: data['bookingId'] as String,
      userId: data['userId'] as String,
      providerId: data['providerId'] as String?,
      amount: (data['amount'] as num?) ?? 0,
      method: data['method'] as String? ?? '',
      gatewayRef: data['gatewayRef'] as String?,
      status: data['status'] as String? ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'providerId': providerId,
      'amount': amount,
      'method': method,
      'gatewayRef': gatewayRef,
      'status': status,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }
}
