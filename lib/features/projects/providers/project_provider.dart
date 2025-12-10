import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/project_repository.dart';
import '../models/project_model.dart';
// Import Auth Provider untuk deteksi perubahan user
import '../../auth/providers/user_provider.dart'; 

final projectListProvider = StreamProvider.autoDispose<List<ProjectModel>>((ref) {
  // 1. Pantau Status Auth
  // Setiap kali user logout/login, baris ini akan memaksa provider refresh!
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      
      // 2. Ambil data project milik USER YANG BARU LOGIN
      final repo = ref.watch(projectRepositoryProvider);
      return repo.getUserProjects(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});