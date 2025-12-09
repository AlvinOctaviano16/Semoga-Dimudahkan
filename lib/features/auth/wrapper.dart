import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import ini harus mengarah ke file yang baru saja Anda perbaiki di atas
import 'presentation/screens/login.dart';
import 'presentation/screens/homepage.dart'; // Pastikan Homepage juga sudah dipindah/disesuaikan
import 'data/auth_repository.dart';

final authStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class Wrapper extends ConsumerWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStreamProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const Homepage(); // User Login -> Masuk Home
        } else {
          return const LoginScreen(); // User Logout -> Masuk Login
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}