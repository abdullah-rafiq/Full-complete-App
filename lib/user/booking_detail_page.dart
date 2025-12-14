// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/services/booking_service.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/common/payment_page.dart' as payment_page;
import 'package:flutter_application_1/common/chat_page.dart' as chat_page;
import 'package:flutter_application_1/common/ui_helpers.dart';

class BookingDetailPage extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailPage({super.key, required this.booking});

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
        title: const Text('Booking details'),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Booking #${booking.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _statusColor(booking.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(booking.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.scheduledTime == null
                              ? 'Scheduled time: Not set'
                              : 'Scheduled time: ${_formatDateTime(booking.scheduledTime)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (booking.address != null &&
                                  booking.address!.isNotEmpty)
                              ? booking.address!
                              : 'Address: Not provided',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PKR ${booking.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.payment_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: booking.paymentStatus == PaymentStatus.pending
                              ? Colors.redAccent.withOpacity(0.12)
                              : Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          booking.paymentStatus == PaymentStatus.pending
                              ? 'Pending'
                              : 'Paid',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: booking.paymentStatus == PaymentStatus.pending
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        booking.paymentStatus == PaymentStatus.pending
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => payment_page.PaymentPage(booking: booking),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Pay now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await BookingService.instance.updateStatus(
                        booking.id,
                        BookingStatus.cancelled,
                      );
                      if (context.mounted) {
                        UIHelpers.showSnack(
                          context,
                          'Booking cancelled (demo only).',
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Cancel booking'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message provider'),
              onPressed: booking.providerId == null
                  ? null
                  : () => _openChatForBooking(context, booking),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case BookingStatus.completed:
      return Colors.green;
    case BookingStatus.cancelled:
      return Colors.redAccent;
    case BookingStatus.inProgress:
    case BookingStatus.onTheWay:
      return Colors.orange;
    default:
      return Colors.blueGrey;
  }
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) return 'Not set';
  final local = dt.toLocal();
  final date = '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date • $time';
}

Future<void> _openChatForBooking(
  BuildContext context,
  BookingModel booking,
) async {
  final current = FirebaseAuth.instance.currentUser;
  if (current == null) {
    UIHelpers.showSnack(context, 'Please log in to send messages.');
    return;
  }

  final providerId = booking.providerId;
  if (providerId == null) {
    UIHelpers.showSnack(
      context,
      'No provider assigned to this booking.',
    );
    return;
  }

  final customerId = booking.customerId;
  final ids = [customerId, providerId]..sort();
  final chatId = ids.join('_');

  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  await chatRef.set(
    {
      'participants': ids,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );

  final otherId = current.uid == customerId ? providerId : customerId;
  final other = await UserService.instance.getById(otherId);
  if (other == null) {
    UIHelpers.showSnack(context, 'Could not load user for chat.');
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => chat_page.ChatPage(
        chatId: chatId,
        otherUser: other,
      ),
    ),
  );
}

