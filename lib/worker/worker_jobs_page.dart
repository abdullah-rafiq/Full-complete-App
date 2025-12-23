import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:assist/models/app_user.dart';
import 'package:assist/models/booking.dart';
import 'package:assist/models/service.dart';
import 'package:assist/services/booking_service.dart';
import 'package:assist/controllers/bookings_controller.dart';
import 'package:assist/localized_strings.dart';
import 'worker_job_detail_page.dart';

class WorkerJobsPage extends StatefulWidget {
  const WorkerJobsPage({super.key});

  @override
  State<WorkerJobsPage> createState() => _WorkerJobsPageState();
}

class _WorkerJobsPageState extends State<WorkerJobsPage> {
  String? _statusFilter; // null = All

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(L10n.workerJobsLoginRequiredMessage())),
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
        title: Text(L10n.workerJobsAppBarTitle()),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<BookingModel>>(
        stream: _withInitialTimeout(
          BookingService.instance.watchProviderBookings(
            user.uid,
            status: _statusFilter,
          ),
          const Duration(seconds: 15),
          debugName: 'providerBookings',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${L10n.workerJobsLoadError()}\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.work_outline,
                    size: 56,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    L10n.workerJobsEmptyMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            );
          }

          Color statusColor(String status) {
            switch (status) {
              case BookingStatus.completed:
                return Colors.green;
              case BookingStatus.cancelled:
                return Colors.redAccent;
              case BookingStatus.inProgress:
              case BookingStatus.onTheWay:
                return Colors.orange;
              case BookingStatus.accepted:
                return Colors.blueAccent;
              default:
                return Colors.blueGrey;
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(L10n.bookingFilterAll(), null),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        L10n.bookingStatusRequested(),
                        BookingStatus.requested,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        L10n.bookingStatusAccepted(),
                        BookingStatus.accepted,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        L10n.bookingStatusInProgress(),
                        BookingStatus.inProgress,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        L10n.bookingStatusCompleted(),
                        BookingStatus.completed,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, ServiceModel?>>(
                  future: BookingsController.loadServicesForBookings(bookings),
                  builder: (context, servicesSnap) {
                    final servicesById =
                        servicesSnap.data ?? <String, ServiceModel?>{};

                    if (servicesSnap.connectionState ==
                            ConnectionState.waiting &&
                        servicesById.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return FutureBuilder<Map<String, AppUser?>>(
                      future: BookingsController.loadCustomersForBookings(
                        bookings,
                      ),
                      builder: (context, customersSnap) {
                        final customersById =
                            customersSnap.data ?? <String, AppUser?>{};

                        if (customersSnap.connectionState ==
                                ConnectionState.waiting &&
                            customersById.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final b = bookings[index];
                            final service = servicesById[b.serviceId];
                            final customer = customersById[b.customerId];

                            final serviceName = service?.name ?? 'Service';
                            final customerName =
                                (customer?.name?.trim().isNotEmpty ?? false)
                                ? customer!.name!.trim()
                                : 'Customer';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WorkerJobDetailPage(booking: b),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.assignment_outlined,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            serviceName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${L10n.workerJobCustomerPrefix()} $customerName',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            b.scheduledTime == null
                                                ? 'Time: not set'
                                                : 'Time: ${_formatDateTime(b.scheduledTime)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (b.address != null &&
                                              b.address!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              b.address!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor(
                                              b.status,
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            b.status,
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder:
                              (separatorContext, separatorIndex) =>
                                  const SizedBox(height: 12),
                          itemCount: bookings.length,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final selected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _statusFilter = status;
        });
      },
    );
  }
}

Stream<T> _withInitialTimeout<T>(
  Stream<T> source,
  Duration timeout, {
  String? debugName,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? timer;
  var gotFirst = false;

  controller = StreamController<T>(
    onListen: () {
      timer = Timer(timeout, () {
        if (gotFirst || controller.isClosed) return;
        controller.addError(
          TimeoutException(
            'Timed out waiting for initial data${debugName == null ? '' : ' ($debugName)'}',
          ),
        );
      });

      sub = source.listen(
        (event) {
          if (!gotFirst) {
            gotFirst = true;
            timer?.cancel();
          }
          controller.add(event);
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      await sub?.cancel();
    },
  );

  return controller.stream;
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) return L10n.commonNotSet();
  final local = dt.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date • $time';
}
