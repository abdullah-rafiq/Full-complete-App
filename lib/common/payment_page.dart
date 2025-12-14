// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/services/booking_service.dart';
import 'package:flutter_application_1/common/ui_helpers.dart';
import 'package:flutter_application_1/common/section_card.dart';

class PaymentPage extends StatelessWidget {
  final BookingModel booking;

  const PaymentPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    Future<void> handlePayment(String method) async {
      await BookingService.instance
          .updatePaymentStatus(booking.id, PaymentStatus.paid);

      if (!context.mounted) return;

      UIHelpers.showSnack(context, 'Marked as paid via $method');

      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Payment'),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pay for booking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Amount: PKR ${booking.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current status: ${booking.paymentStatus}',
                  style:
                      const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.deepPurple),
              title: const Text('JazzCash'),
              subtitle: const Text('Pay using your JazzCash mobile wallet.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                handlePayment('JazzCash');
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet,
                  color: Colors.green),
              title: const Text('Easypaisa'),
              subtitle: const Text('Pay using your Easypaisa mobile wallet.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                handlePayment('Easypaisa');
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Debit / Credit Card'),
              subtitle: const Text('Pay with Visa, Mastercard or other cards.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                handlePayment('Card / Bank');
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Note: This is a demo payment screen. Connect these methods to real payment gateways for production use.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
