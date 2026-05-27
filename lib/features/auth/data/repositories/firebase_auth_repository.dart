import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paypact/features/auth/data/models/user_model.dart';
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
        final doc =
            await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
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
    return model;
  }

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
    return model;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    // initialize is idempotent – safe to call each time
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) throw Exception('Google sign-in: no idToken returned');

    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final fbUser = userCredential.user!;

    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final doc = await docRef.get();
    final model = UserModel(
      id: fbUser.uid,
      name: fbUser.displayName ?? googleUser.displayName ?? '',
      email: fbUser.email ?? googleUser.email,
      photoUrl: fbUser.photoURL,
    );
    if (!doc.exists) {
      await docRef.set(model.toMap());
    }
    return model;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }
}
