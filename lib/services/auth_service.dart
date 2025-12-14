import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> ensureUserDocument({
    required User firebaseUser,
    required UserRole role,
  }) async {
    final userRef = _db.collection('users').doc(firebaseUser.uid);
    final snapshot = await userRef.get();
    if (snapshot.exists) return;

    final appUser = AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      role: role,
      createdAt: DateTime.now(),
    );

    await userRef.set(appUser.toMap(), SetOptions(merge: true));

    await _db.collection('admin_notifications').add({
      'type': 'new_user',
      'userId': firebaseUser.uid,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureAdminUser(User firebaseUser) async {
    final userRef = _db.collection('users').doc(firebaseUser.uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      await userRef.set(
        {
          'role': UserRole.admin.name,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName,
          'phone': firebaseUser.phoneNumber,
        },
        SetOptions(merge: true),
      );
      return;
    }

    final appUser = AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );

    await userRef.set(appUser.toMap(), SetOptions(merge: true));

    await _db.collection('admin_notifications').add({
      'type': 'new_user',
      'userId': firebaseUser.uid,
      'role': UserRole.admin.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
