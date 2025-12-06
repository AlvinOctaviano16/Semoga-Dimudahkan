import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/project_repository.dart';
import '../models/project_model.dart';

// 1. Provider untuk Repository (Biar bisa dipanggil di mana aja)
final projectRepositoryProvider = Provider((ref) => ProjectRepository());

// 2. Provider untuk List Project (Stream)
// UI akan "watch" provider ini. Kalau data berubah, UI otomatis refresh.
final projectListProvider = StreamProvider<List<ProjectModel>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  
  // Ambil user ID yang sedang login
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    // Kalau belum login, kembalikan list kosong
    return Stream.value([]);
  }

  return repo.getUserProjects(user.uid);
});