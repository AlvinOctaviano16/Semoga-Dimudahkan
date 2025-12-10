import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Kita matikan dulu karena bypass

// Pastikan import ini sesuai dengan lokasi file Anda
import '../repositories/project_repository.dart';
import '../models/project_model.dart';

// 1. Provider untuk Repository
// Ini menyediakan instance ProjectRepository ke seluruh aplikasi
final projectRepositoryProvider = Provider((ref) => ProjectRepository());

// 2. Provider untuk List Project (Stream)
// UI Dashboard akan "mendengarkan" (watch) provider ini
final projectListProvider = StreamProvider<List<ProjectModel>>((ref) {
  // Ambil instance repository dari provider di atas
  final repo = ref.watch(projectRepositoryProvider);
  
  // --- BYPASS AUTH LOGIC (SEMENTARA) ---
  // Karena fitur Auth teman bermasalah, kita pakai ID manual dulu.
  // Pastikan ID ini SAMA dengan yang ada di CreateProjectScreen.
  const fakeUserId = "user-bypass-123"; 

  // Panggil fungsi di repository untuk mengambil data milik user palsu ini
  return repo.getUserProjects(fakeUserId);
});