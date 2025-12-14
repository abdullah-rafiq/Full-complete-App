import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';

class BookingService {
  BookingService._();

  static final BookingService instance = BookingService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bookings');

  Future<String> createBooking(BookingModel booking) async {
    final doc = await _col.add(booking.toMap());
    // Simple analytics/logging
    // ignore: avoid_print
    print('BOOKING_CREATED id=${doc.id} customer=${booking.customerId} provider=${booking.providerId} service=${booking.serviceId}');
    return doc.id;
  }

  Future<void> updateStatus(String bookingId, String status) {
    // Simple analytics/logging
    // ignore: avoid_print
    print('BOOKING_STATUS_UPDATED id=$bookingId status=$status');
    return _col.doc(bookingId).update({'status': status});
  }

  Future<void> updatePaymentStatus(String bookingId, String paymentStatus) {
    // Simple analytics/logging
    // ignore: avoid_print
    print('BOOKING_PAYMENT_UPDATED id=$bookingId paymentStatus=$paymentStatus');
    return _col.doc(bookingId).update({'paymentStatus': paymentStatus});
  }

  Stream<List<BookingModel>> watchCustomerBookings(String customerId) {
    return _col
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BookingModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<List<BookingModel>> watchProviderBookings(String providerId,
      {String? status}) {
    Query<Map<String, dynamic>> query =
        _col.where('providerId', isEqualTo: providerId);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => BookingModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
