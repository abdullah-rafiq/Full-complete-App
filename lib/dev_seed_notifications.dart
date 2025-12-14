import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Seed demo notifications into the `notifications` collection.
///
/// This is intended for development-only use from an admin/dev UI.
Future<void> seedDemoNotifications() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  final now = DateTime.now();

  // Notifications for the currently signed-in user (typically admin when run
  // from the admin profile page).
  final current = FirebaseAuth.instance.currentUser;
  if (current != null) {
    final uid = current.uid;

    final notifWelcome = db
        .collection('notifications')
        .doc('notif_${uid}_welcome');
    batch.set(notifWelcome, {
      'userId': uid,
      'title': 'Welcome to the admin tools',
      'body': 'You can use the dev buttons to seed demo data for testing.',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
    });

    final notifSummary =
        db.collection('notifications').doc('notif_${uid}_daily_summary');
    batch.set(notifSummary, {
      'userId': uid,
      'title': 'Daily summary ready',
      'body': 'Your daily bookings and revenue summary is ready to review.',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
    });

    final notifDisputes =
        db.collection('notifications').doc('notif_${uid}_disputes');
    batch.set(notifDisputes, {
      'userId': uid,
      'title': 'Dispute overview',
      'body': 'There are new disputes flagged for recent bookings.',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
    });
  }

  // Demo notifications for seeded sample users (if they exist).
  final demoNotif1 = db.collection('notifications').doc('notif_user_customer_1_1');
  batch.set(demoNotif1, {
    'userId': 'user_customer_1',
    'title': 'Booking confirmed',
    'body': 'Your booking booking_1 has been accepted.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 25, 11)),
  });

  final demoNotif2 = db.collection('notifications').doc('notif_user_customer_2_1');
  batch.set(demoNotif2, {
    'userId': 'user_customer_2',
    'title': 'Worker on the way',
    'body': 'Your worker is on the way for booking booking_4.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 18, 10, 30)),
  });

  final demoNotif3 = db.collection('notifications').doc('notif_user_provider_1_1');
  batch.set(demoNotif3, {
    'userId': 'user_provider_1',
    'title': 'New booking assigned',
    'body': 'You have a new booking request from user_customer_1.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 25, 10, 0)),
  });

  await batch.commit();
}
