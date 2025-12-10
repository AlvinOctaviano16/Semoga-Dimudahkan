import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/project_repository.dart';
import '../models/project_model.dart';

// Stream Provider to listen to the projects of the CURRENT user
final projectListProvider = StreamProvider<List<ProjectModel>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  
  // 1. Get Real User
  final user = FirebaseAuth.instance.currentUser;

  // 2. Safety Check: If not logged in, return empty list
  if (user == null) {
    return Stream.value([]);
  }

  // 3. Fetch Real Data
  return repo.getUserProjects(user.uid);
});