// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/services/user_service.dart';
import 'package:flutter_application_1/common/section_card.dart';
import 'package:flutter_application_1/controllers/worker_job_controller.dart';

class WorkerJobDetailPage extends StatelessWidget {
  final BookingModel booking;

  const WorkerJobDetailPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Job details'),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<AppUser?>(
                    future: UserService.instance.getById(booking.customerId),
                    builder: (context, snapshot) {
                      final customer = snapshot.data;
                      final name =
                          (customer?.name?.trim().isNotEmpty ?? false)
                              ? customer!.name!.trim()
                              : 'Customer';
                      final phone =
                          (customer?.phone?.trim().isNotEmpty ?? false)
                              ? customer!.phone!.trim()
                              : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer: $name',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (phone != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: onSurface.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Job #${booking.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(booking.status).withOpacity(0.12),
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: onSurface.withOpacity(0.7),
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
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (booking.address != null && booking.address!.isNotEmpty)
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
                      Icon(
                        Icons.attach_money,
                        size: 18,
                        color: onSurface.withOpacity(0.7),
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
                      Icon(
                        Icons.payment_outlined,
                        size: 18,
                        color: onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment: ${booking.paymentStatus}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _primaryActionEnabled
                        ? () async {
                            await _handlePrimaryAction(context);
                          }
                        : null,
                    child: Text(_primaryActionLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _secondaryActionEnabled
                        ? () async {
                            await _handleSecondaryAction(context);
                          }
                        : null,
                    child: Text(_secondaryActionLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message customer'),
              onPressed: () => _openChatForJob(context, booking),
            ),
          ],
        ),
      ),
    );
  }

  bool get _primaryActionEnabled {
    switch (booking.status) {
      case BookingStatus.requested:
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.inProgress:
        return true;
      default:
        return false;
    }
  }

  bool get _secondaryActionEnabled {
    switch (booking.status) {
      case BookingStatus.requested:
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.inProgress:
        return true;
      default:
        return false;
    }
  }

  String get _primaryActionLabel {
    switch (booking.status) {
      case BookingStatus.requested:
        return 'Accept job';
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
        return 'Start job';
      case BookingStatus.inProgress:
        return 'Complete job';
      default:
        return 'No action';
    }
  }

  String get _secondaryActionLabel {
    switch (booking.status) {
      case BookingStatus.requested:
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.inProgress:
        return 'Cancel job';
      default:
        return 'Unavailable';
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
      case BookingStatus.accepted:
        return Colors.blueAccent;
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

  Future<void> _handlePrimaryAction(BuildContext context) async {
    await WorkerJobController.handlePrimaryAction(context, booking);
  }

  Future<void> _handleSecondaryAction(BuildContext context) async {
    await WorkerJobController.handleSecondaryAction(context, booking);
  }

  Future<void> _openChatForJob(
    BuildContext context,
    BookingModel booking,
  ) async {
    await WorkerJobController.openChatForJob(context, booking);
  }
}

