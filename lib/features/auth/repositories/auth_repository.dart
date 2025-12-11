import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

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

  // Get Multiple Users by IDs (for members)
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      // Karena Firestore 'whereIn' maksimal 10, kita pakai cara aman:
      // Ambil satu-satu secara paralel (Future.wait).
      // Ini lebih aman untuk skala kecil/menengah.
      final futures = userIds.map((uid) => _firestore.collection('users').doc(uid).get());
      final snapshots = await Future.wait(futures);

      return snapshots
          .where((doc) => doc.exists) // Pastikan user masih ada
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception("Gagal mengambil data member: $e");
    }
  }

  //Update FCM Token
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(), // Opsional: untuk tahu kapan terakhir aktif
      });
    } catch (e) {
      // Ignore error jika user belum ada doc-nya
      print("Gagal update token: $e");
    }
  }
  
  // 1. Fungsi untuk Verifikasi Password Lama (Wajib demi keamanan)
  Future<void> reauthenticate(String email, String password) async {
    final user = _auth.currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    }
  }

  // 2. Fungsi Ganti Password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // 3. Fungsi Ganti Email
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      // verifyBeforeUpdateEmail mengirim email konfirmasi ke alamat baru
      // sebelum benar-benar menggantinya di akun. Ini lebih aman.
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }
}