import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// 1. Provider Kecil untuk Memantau: Siapa yang sedang login?
// Ini akan mendeteksi perubahan dari Ulil -> Logout -> Farid
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Provider Profile Utama
// Gunakan .autoDispose agar data langsung dibuang saat halaman ditutup
final userProfileProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  
  // A. PENTING: Kita 'watch' status login.
  // Artinya: Setiap kali user berubah, provider ini DIPAKSA jalan ulang.
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      // Jika tidak ada user login, kembalikan stream kosong
      if (user == null) return const Stream.empty();

      // Jika ada user (Farid), ambil data dia dari Repo
      final repo = ref.watch(authRepositoryProvider);
      return repo.getUserData(); 
    },
    // Saat loading/error auth, kirim stream kosong dulu
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});