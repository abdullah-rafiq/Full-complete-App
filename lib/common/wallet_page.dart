// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/services/booking_service.dart';
import 'package:flutter_application_1/common/payment_page.dart';
import 'package:flutter_application_1/common/ui_helpers.dart';
import 'package:flutter_application_1/common/section_card.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Wallet'),
        ),
        body: const Center(child: Text('Please log in to view your wallet.')),
      );
    }

    Future<void> showTopUpDialog(String method) async {
      final controller = TextEditingController();
      final amount = await showDialog<num?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Top up via $method'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount (PKR)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = num.tryParse(controller.text.trim());
                  if (value == null || value <= 0) {
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (amount == null) return;

      await UserService.instance.addToWallet(current.uid, amount);

      if (!context.mounted) return;

      UIHelpers.showSnack(
        context,
        'Wallet topped up by PKR ${amount.toStringAsFixed(0)} via $method',
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Wallet'),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<AppUser?>(
        stream: UserService.instance.watchUser(current.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load wallet.'));
          }

          final profile = snapshot.data;
          final balance = profile?.walletBalance ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance card
                SectionCard(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PKR ${balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quick actions row (demo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showTopUpDialog('Top-up'),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add money'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          UIHelpers.showSnack(
                            context,
                            'Link card is a placeholder. Integrate real gateway later.',
                          );
                        },
                        icon: const Icon(Icons.credit_card),
                        label: const Text('Link card'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Unpaid bookings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<BookingModel>>(
                    stream: BookingService.instance.watchCustomerBookings(
                      current.uid,
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      if (snap.hasError) {
                        return const Center(
                          child: Text('Could not load unpaid bookings (demo).'),
                        );
                      }

                      final all = snap.data ?? [];
                      final unpaid = all
                          .where(
                            (b) => b.paymentStatus == PaymentStatus.pending,
                          )
                          .toList();

                      if (unpaid.isEmpty) {
                        return const Center(
                          child: Text(
                            'No unpaid bookings. You\'re all settled!',
                            style: TextStyle(fontSize: 13),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemBuilder: (context, index) {
                          final b = unpaid[index];
                          return SectionCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Booking: ${b.id}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Amount: PKR ${b.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaymentPage(booking: b),
                                      ),
                                    );
                                  },
                                  child: const Text('Pay'),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (separatorContext, separatorIndex) =>
                            const SizedBox(height: 8),
                        itemCount: unpaid.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
