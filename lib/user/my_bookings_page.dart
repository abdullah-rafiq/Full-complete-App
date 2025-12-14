// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/services/booking_service.dart';
import 'package:flutter_application_1/controllers/bookings_controller.dart';
import 'package:flutter_application_1/common/payment_page.dart';
import 'package:flutter_application_1/user/booking_detail_page.dart';
import 'package:flutter_application_1/common/section_card.dart';
import 'package:flutter_application_1/localized_strings.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(L10n.bookingsLoginRequiredMessage()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(L10n.bookingsAppBarTitle()),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: BookingService.instance.watchCustomerBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(L10n.bookingsLoadError()),
            );
          }

          final bookings = snapshot.data ?? [];

          Color statusColor(String status) {
            switch (status) {
              case BookingStatus.completed:
                return Colors.green;
              case BookingStatus.cancelled:
                return Colors.redAccent;
              case BookingStatus.inProgress:
              case BookingStatus.onTheWay:
              case BookingStatus.accepted:
                return Colors.orange;
              case BookingStatus.requested:
              default:
                return Colors.blueGrey;
            }
          }

          String statusLabel(String status) {
            switch (status) {
              case BookingStatus.completed:
                return L10n.bookingStatusCompleted();
              case BookingStatus.cancelled:
                return L10n.bookingStatusCancelled();
              case BookingStatus.inProgress:
                return L10n.bookingStatusInProgress();
              case BookingStatus.onTheWay:
                return L10n.bookingStatusOnTheWay();
              case BookingStatus.accepted:
                return L10n.bookingStatusAccepted();
              case BookingStatus.requested:
              default:
                return L10n.bookingStatusRequested();
            }
          }

          Widget buildBookingTile(BookingModel b, ServiceModel? service) {
            final serviceName = service?.name ?? 'Service';

            return SectionCard(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailPage(booking: b),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.cleaning_services_rounded,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.scheduledTime == null
                                ? 'Time: ${L10n.commonNotSet()}'
                                : 'Time: ${_formatDateTime(b.scheduledTime)}',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(b.status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel(b.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor(b.status),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PKR ${b.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (b.paymentStatus == PaymentStatus.pending)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PaymentPage(booking: b),
                                ),
                              );
                            },
                            child: Text(L10n.bookingPayNowCta()),
                          )
                        else
                          Text(
                            L10n.bookingPaidLabel(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final statusOrder = [
            BookingStatus.requested,
            BookingStatus.accepted,
            BookingStatus.onTheWay,
            BookingStatus.inProgress,
            BookingStatus.completed,
            BookingStatus.cancelled,
          ];

          final statusLabels = [
            L10n.bookingStatusRequested(),
            L10n.bookingStatusAccepted(),
            L10n.bookingStatusOnTheWay(),
            L10n.bookingStatusInProgress(),
            L10n.bookingStatusCompleted(),
            L10n.bookingStatusCancelled(),
          ];

          return DefaultTabController(
            length: statusOrder.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: [
                    for (int i = 0; i < statusOrder.length; i++)
                      Tab(
                        child: Text(
                          statusLabels[i],
                          style: TextStyle(
                            color: statusColor(statusOrder[i]),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final status in statusOrder)
                        Builder(
                          builder: (context) {
                            final filtered = bookings
                                .where((b) => b.status == status)
                                .toList();
                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  L10n.bookingsEmptyForStatus(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }
                            return FutureBuilder<
                                Map<String, ServiceModel?>>(
                              future: BookingsController
                                  .loadServicesForBookings(filtered),
                              builder: (context, servicesSnap) {
                                final servicesById =
                                    servicesSnap.data ??
                                        <String, ServiceModel?>{};

                                if (servicesSnap.connectionState ==
                                        ConnectionState.waiting &&
                                    servicesById.isEmpty) {
                                  return const Center(
                                    child:
                                        CircularProgressIndicator(),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filtered.length,
                                  separatorBuilder:
                                      (separatorContext, separatorIndex) =>
                                          const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final b = filtered[index];
                                    final service =
                                        servicesById[b.serviceId];
                                    return buildBookingTile(
                                      b,
                                      service,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
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

