import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../repositories/project_repository.dart';

// UBAH DARI FutureProvider MENJADI StreamProvider
final projectMembersProvider = StreamProvider.family.autoDispose<List<UserModel>, String>((ref, projectId) {
  final projectRepo = ref.watch(projectRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  // 1. Dengarkan Stream Project (Realtime)
  return projectRepo.getProjectStream(projectId).asyncMap((project) async {
    
    // 2. Setiap kali ada perubahan di project, kode ini berjalan ulang:
    if (project.members.isEmpty) {
      return <UserModel>[]; // Return list kosong jika tidak ada member
    }

    // 3. Ambil detail user terbaru berdasarkan list ID yang baru
    return await authRepo.getUsersByIds(project.members);
  });
});