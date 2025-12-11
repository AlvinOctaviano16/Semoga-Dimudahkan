import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();

      final repo = ref.watch(authRepositoryProvider);
      return repo.getUserData(); 
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});