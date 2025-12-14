import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('analytics_events');

  Future<void> logEvent(String type, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    await _col.add(<String, dynamic>{
      'type': type,
      'userId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      ...data,
    });
  }
}
