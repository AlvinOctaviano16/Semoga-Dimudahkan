import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider Repository
final authRepositoryProvider = Provider((ref) => AuthRepository(
  FirebaseAuth.instance, 
  FirebaseFirestore.instance
));

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String name) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    if (cred.user != null) {
      // Simpan data user ke Firestore (PENTING UNTUK PROFIL NANTI)
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'name': name, 
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Kirim Verifikasi Email
      await cred.user!.sendEmailVerification();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // Get User Data Stream
  Stream<DocumentSnapshot> getUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    } else {
      throw Exception("User not logged in");
    }
  }

  // Update User Profile
  Future<void> updateProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
      });
    }
  }
}