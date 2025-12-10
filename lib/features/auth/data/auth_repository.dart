import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
  FirebaseAuth.instance, 
  FirebaseFirestore.instance
));

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  // --- STREAM AUTH STATE ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // 1. Sign In
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 2. Sign Up (Dengan Simpan Data ke Firestore)
  Future<void> signUp(String email, String password, String name) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email, 
      password: password
    );
    
    if (cred.user != null) {
      // Simpan data awal user ke Firestore
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

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. Forgot Password
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 5. Update Profile (INI YANG HILANG SEBELUMNYA)
  Future<void> updateProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
      });
    } else {
      throw Exception("User tidak ditemukan/login");
    }
  }

  // 6. Get User Data (Untuk Menampilkan Profil)
  Stream<DocumentSnapshot> getUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    } else {
      throw Exception("User tidak login");
    }
  }
}