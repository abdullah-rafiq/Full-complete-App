import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:assist/common/ui_helpers.dart';
import 'package:assist/models/booking.dart';
import 'package:assist/services/booking_service.dart';
import 'package:assist/services/user_service.dart';
import 'package:assist/common/chat_page.dart';

class WorkerJobController {
  const WorkerJobController._();

  /// Handle the primary action for a worker job (accept/start/complete).
  static Future<void> handlePrimaryAction(
    BuildContext context,
    BookingModel booking,
  ) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      UIHelpers.showSnack(context, 'Please log in to update job status.');
      return;
    }

    final provider = await UserService.instance.getById(current.uid);
    if (!context.mounted) return;
    if (provider == null || provider.verificationStatus != 'approved') {
      UIHelpers.showSnack(
        context,
        'Your account is not verified yet. Complete verification before accepting or starting jobs.',
      );
      return;
    }

    String? newStatus;
    switch (booking.status) {
      case BookingStatus.requested:
        newStatus = BookingStatus.accepted;
        break;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
        newStatus = BookingStatus.inProgress;
        break;
      case BookingStatus.inProgress:
        newStatus = BookingStatus.completed;
        break;
      default:
        break;
    }

    if (newStatus == null) return;

    try {
      await BookingService.instance.updateStatus(booking.id, newStatus);
      if (!context.mounted) return;
      UIHelpers.showSnack(context, 'Job status updated to $newStatus.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showSnack(context, 'Could not update job status: $e');
    }
  }

  /// Handle the secondary action (cancel job).
  static Future<void> handleSecondaryAction(
    BuildContext context,
    BookingModel booking,
  ) async {
    try {
      await BookingService.instance.updateStatus(
        booking.id,
        BookingStatus.cancelled,
      );
      if (!context.mounted) return;
      UIHelpers.showSnack(context, 'Job cancelled.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      UIHelpers.showSnack(context, 'Could not cancel job: $e');
    }
  }

  /// Open chat between worker and customer for this job.
  static Future<void> openChatForJob(
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
      UIHelpers.showSnack(context, 'No provider assigned to this job.');
      return;
    }

    final customerId = booking.customerId;
    final ids = [customerId, providerId]..sort();
    final chatId = ids.join('_');

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.set({
      'participants': ids,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!context.mounted) return;

    final otherId = current.uid == customerId ? providerId : customerId;
    final other = await UserService.instance.getById(otherId);
    if (!context.mounted) return;
    if (other == null) {
      UIHelpers.showSnack(context, 'Could not load user for chat.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(chatId: chatId, otherUser: other),
      ),
    );
  }
}
