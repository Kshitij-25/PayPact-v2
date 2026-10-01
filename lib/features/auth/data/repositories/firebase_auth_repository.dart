import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paypact/features/auth/data/models/user_model.dart';
import 'package:paypact/features/auth/data/user_directory.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository(this._auth, this._firestore);

  @override
  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists) {
          // People search is by lower-cased name; accounts created before that
          // existed get it filled in the next time they open the app.
          final data = doc.data() ?? {};
          final name = data['name'];
          if (name is String && name.isNotEmpty && data['nameLower'] == null) {
            doc.reference
                .set({'nameLower': name.trim().toLowerCase()},
                    SetOptions(merge: true))
                .catchError((_) {});
          }
          final user = UserModel.fromFirestore(doc);
          // Keep the public directory entry (people search) current; accounts
          // from before it existed get one the next time they open the app.
          UserDirectory.upsert(_firestore, user.id,
              name: user.name, email: user.email, photoUrl: user.photoUrl);
          return user;
        }
        return UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? '',
          email: fbUser.email ?? '',
          photoUrl: fbUser.photoURL,
        );
      } catch (_) {
        return UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? '',
          email: fbUser.email ?? '',
          photoUrl: fbUser.photoURL,
        );
      }
    });
  }

  @override
  UserEntity? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return UserModel(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      photoUrl: fbUser.photoURL,
    );
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final fbUser = credential.user!;
    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      // Backfill email field if missing (accounts created before this write was added)
      final data = doc.data() ?? {};
      if (!data.containsKey('email') || data['email'] == '') {
        await docRef.update({'email': fbUser.email ?? email});
      }
      return UserModel.fromFirestore(await docRef.get());
    }
    final model = UserModel(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? email,
      photoUrl: fbUser.photoURL,
    );
    await docRef.set(model.toMap());
    await _publish(model);
    return model;
  }

  Future<void> _publish(UserEntity u) => UserDirectory.upsert(_firestore, u.id,
      name: u.name, email: u.email, photoUrl: u.photoUrl);

  @override
  Future<UserEntity> createUserWithEmailAndPassword(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final fbUser = credential.user!;
    await fbUser.updateDisplayName(name);

    final model = UserModel(
      id: fbUser.uid,
      name: name,
      email: email,
      photoUrl: null,
    );
    await _firestore.collection('users').doc(fbUser.uid).set(model.toMap());
    await _publish(model);
    // Best-effort: failing to send the email must not fail sign-up.
    try {
      await fbUser.sendEmailVerification();
    } catch (e) {
      debugPrint('sendEmailVerification failed: $e');
    }
    return model;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    fb.UserCredential userCredential;

    if (kIsWeb) {
      final provider = fb.GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      userCredential = await _auth.signInWithPopup(provider);
    } else {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('Google sign-in: no idToken returned');
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      userCredential = await _auth.signInWithCredential(credential);
    }

    final fbUser = userCredential.user!;

    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();
    final model = UserModel(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      photoUrl: fbUser.photoURL,
    );
    if (!doc.exists) {
      await docRef.set(model.toMap());
    }
    await _publish(model);
    return model;
  }

  @override
  Future<UserEntity> signInWithApple() async {
    final provider = fb.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final userCredential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    final fbUser = userCredential.user!;

    // Apple only reveals the name the first time, and may hide the email.
    final email = fbUser.email ?? '';
    final name = (fbUser.displayName?.trim().isNotEmpty ?? false)
        ? fbUser.displayName!.trim()
        : (email.contains('@') ? email.split('@').first : 'PayPact user');
    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final model = UserModel(
        id: fbUser.uid, name: name, email: email, photoUrl: fbUser.photoURL);
    if (!(await docRef.get()).exists) await docRef.set(model.toMap());
    await _publish(model);
    return model;
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    await user.sendEmailVerification();
  }

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? true;

  @override
  Future<bool> reloadEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return true;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? true;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      // A session that never used Google sign-in has nothing to sign out of,
      // and this call can wait forever in that case.
      GoogleSignIn.instance
          .signOut()
          .timeout(const Duration(seconds: 3))
          .catchError((_) {}),
    ]);
  }
}
