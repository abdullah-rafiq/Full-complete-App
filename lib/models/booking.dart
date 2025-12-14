import 'package:cloud_firestore/cloud_firestore.dart';

class BookingStatus {
  static const requested = 'Requested';
  static const accepted = 'Accepted';
  static const onTheWay = 'OnTheWay';
  static const inProgress = 'InProgress';
  static const completed = 'Completed';
  static const cancelled = 'Cancelled';
}

class PaymentStatus {
  static const pending = 'Pending';
  static const paid = 'Paid';
  static const failed = 'Failed';
  static const refunded = 'Refunded';
}

class BookingModel {
  final String id;
  final String serviceId;
  final String customerId;
  final String? providerId;
  final String status;
  final DateTime? scheduledTime;
  final DateTime? createdAt;
  final GeoPoint? location;
  final String? address;
  final num price;
  final String paymentStatus;
  final String? paymentMethod; // jazzcash | easypaisa | card | cod
  final String? paymentProviderId; // PSP transaction / intent id
  final num? paymentAmount; // amount actually charged (PKR)
  final String? notes;
  final String? cancelledBy; // worker | customer | system
  final bool? isNoShow; // true if provider never showed up
  final bool? hasDispute; // true if this booking had a dispute

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.customerId,
    this.providerId,
    this.status = BookingStatus.requested,
    this.scheduledTime,
    this.createdAt,
    this.location,
    this.address,
    this.price = 0,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    this.paymentProviderId,
    this.paymentAmount,
    this.notes,
    this.cancelledBy,
    this.isNoShow,
    this.hasDispute,
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> data) {
    return BookingModel(
      id: id,
      serviceId: data['serviceId'] as String,
      customerId: data['customerId'] as String,
      providerId: data['providerId'] as String?,
      status: data['status'] as String? ?? BookingStatus.requested,
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      location: data['location'] as GeoPoint?,
      address: data['address'] as String?,
      price: (data['price'] as num?) ?? 0,
      paymentStatus:
          data['paymentStatus'] as String? ?? PaymentStatus.pending,
      paymentMethod: data['paymentMethod'] as String?,
      paymentProviderId: data['paymentProviderId'] as String?,
      paymentAmount: data['paymentAmount'] as num?,
      notes: data['notes'] as String?,
      cancelledBy: data['cancelledBy'] as String?,
      isNoShow: data['isNoShow'] as bool?,
      hasDispute: data['hasDispute'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'customerId': customerId,
      'providerId': providerId,
      'status': status,
      'scheduledTime':
          scheduledTime == null ? null : Timestamp.fromDate(scheduledTime!),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'location': location,
      'address': address,
      'price': price,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentProviderId': paymentProviderId,
      'paymentAmount': paymentAmount,
      'notes': notes,
      'cancelledBy': cancelledBy,
      'isNoShow': isNoShow,
      'hasDispute': hasDispute,
    };
  }
}
