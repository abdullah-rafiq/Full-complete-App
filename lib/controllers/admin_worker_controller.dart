import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/common/ui_helpers.dart';

class AdminWorkerController {
  const AdminWorkerController._();

  /// Approve a worker: mark verified and set overall verificationStatus
  /// to 'approved'.
  static Future<void> approveWorker(
    BuildContext context,
    String workerId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(workerId).update({
        'verified': true,
        'verificationStatus': 'approved',
      });

      UIHelpers.showSnack(context, 'Worker approved successfully.');
    } catch (e) {
      UIHelpers.showSnack(context, 'Could not approve worker: $e');
    }
  }

  /// Prompt admin for a rejection reason. Returns null if cancelled.
  static Future<String?> promptRejectReason(BuildContext context) async {
    final controller = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject worker'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    return reason;
  }

  /// Reject a worker with an optional reason.
  static Future<void> rejectWorker(
    BuildContext context,
    String workerId, {
    String? reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(workerId).update({
        'verificationStatus': 'rejected',
        'verificationReason': (reason == null || reason.trim().isEmpty)
            ? null
            : reason.trim(),
      });

      UIHelpers.showSnack(context, 'Worker rejected.');
    } catch (e) {
      UIHelpers.showSnack(context, 'Could not reject worker: $e');
    }
  }

  /// Update a single verification document's status and recompute overall
  /// verificationStatus for the worker.
  static Future<void> updateDocumentStatus(
    BuildContext context, {
    required String workerId,
    required Map<String, dynamic> currentData,
    required String statusField,
    required String newStatus,
  }) async {
    try {
      final Map<String, String> statuses = {
        'cnicFrontStatus': statusField == 'cnicFrontStatus'
            ? newStatus
            : (currentData['cnicFrontStatus'] as String? ?? 'pending'),
        'cnicBackStatus': statusField == 'cnicBackStatus'
            ? newStatus
            : (currentData['cnicBackStatus'] as String? ?? 'pending'),
        'selfieStatus': statusField == 'selfieStatus'
            ? newStatus
            : (currentData['selfieStatus'] as String? ?? 'pending'),
        'shopStatus': statusField == 'shopStatus'
            ? newStatus
            : (currentData['shopStatus'] as String? ?? 'pending'),
      };

      String overall;
      if (statuses.values.every((s) => s == 'approved')) {
        overall = 'approved';
      } else if (statuses.values.any((s) => s == 'rejected')) {
        overall = 'rejected';
      } else {
        overall = 'pending';
      }

      final updates = <String, dynamic>{
        statusField: newStatus,
        'verificationStatus': overall,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .update(updates);

      UIHelpers.showSnack(
        context,
        newStatus == 'approved'
            ? 'Document marked as passed.'
            : 'Document marked for resubmission.',
      );
    } catch (e) {
      UIHelpers.showSnack(context, 'Could not update status: $e');
    }
  }
}
