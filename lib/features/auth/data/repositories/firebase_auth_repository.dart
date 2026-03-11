import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/auth/data/models/user_model.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static const _usersCollection = 'users';

  @override
  Stream<UserEntity?> get authStateChanges => _firebaseAuth
          .authStateChanges()
          // Firebase briefly emits null on startup while restoring a persisted
          // session. `currentUser` is synchronously available from the local cache
          // even at that instant. We drop the spurious null so the app never
          // flashes to the sign-in screen during restore.
          .where((user) => user != null || _firebaseAuth.currentUser == null)
          .asyncMap((fb.User? user) async {
        if (user == null) return null;
        final doc =
            await _firestore.collection(_usersCollection).doc(user.uid).get();
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc.data()!, doc.id).toEntity();
      });

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ── Web: use Firebase's built-in popup flow ────────────────────────
        // GoogleSignIn.authenticate() is NOT supported on web. Instead, use
        // FirebaseAuth.signInWithPopup which handles the OAuth redirect internally.
        final provider = fb.GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final userCredential = await _firebaseAuth.signInWithPopup(provider);
        return _upsertUserDocument(userCredential.user!);
      } else {
        // ── Mobile / Desktop: use the GoogleSignIn package ─────────────────
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          // google_sign_in v7 authenticate() only exposes idToken.
          // Firebase Auth accepts a Google credential with idToken alone.
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await _firebaseAuth.signInWithCredential(credential);
        return _upsertUserDocument(userCredential.user!);
      }
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Authentication failed'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _upsertUserDocument(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Sign in failed'));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      return _upsertUserDocument(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Registration failed'));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const Left(AuthFailure('Not authenticated'));
    return _upsertUserDocument(user);
  }

  @override
  Future<Either<AuthFailure, Unit>> updateFcmToken(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return const Left(AuthFailure('Not authenticated'));
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).update({
        'fcmToken': token,
      });
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Failed to send reset email'));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return const Left(AuthFailure('Not authenticated'));
      await _firestore.collection(_usersCollection).doc(user.uid).delete();
      await user.delete();
      return const Right(unit);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Failed to delete account'));
    }
  }

  Future<Either<AuthFailure, UserEntity>> _upsertUserDocument(
      fb.User user) async {
    try {
      final ref = _firestore.collection(_usersCollection).doc(user.uid);
      final doc = await ref.get();
      late UserModel model;
      if (!doc.exists) {
        model = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await ref.set(model.toFirestore());
      } else {
        model = UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}
