import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';

final projectRepositoryProvider = Provider((ref) => ProjectRepository());

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _projects => _firestore.collection('projects');

  // 1. CREATE (Sudah Ada)
  Future<void> createProject({required String name, required String description, required String ownerId}) async {
    try {
      String inviteCode = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      await _projects.add({
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'members': [ownerId], // Owner otomatis jadi member
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // 2. READ (FIXED: Filter Array Contains)
  // Hanya ambil project di mana User ID ada di dalam list 'members'
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _projects
        .where('members', arrayContains: userId) // 🔥 INI KUNCINYA
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 3. JOIN PROJECT (FITUR BARU)
  Future<void> joinProject({required String inviteCode, required String userId}) async {
    try {
      // Cari project dengan kode tersebut
      final query = await _projects.where('inviteCode', isEqualTo: inviteCode).get();

      if (query.docs.isEmpty) {
        throw "Kode undangan tidak valid/tidak ditemukan.";
      }

      final doc = query.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final members = List<String>.from(data['members'] ?? []);

      // Cek apakah user sudah bergabung
      if (members.contains(userId)) {
        throw "Anda sudah bergabung di proyek ini.";
      }

      // Tambahkan User ID ke array 'members'
      await doc.reference.update({
        'members': FieldValue.arrayUnion([userId])
      });

    } catch (e) {
      throw e.toString();
    }
  }

  // ... (Fungsi Update, Delete, getProjectById biarkan seperti sebelumnya)
   Future<ProjectModel?> getProjectById(String projectId) async {
    final doc = await _projects.doc(projectId).get();
    if (doc.exists) return ProjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    return null;
  }
  
  Future<void> updateProject({required String projectId, required String name, required String description}) async {
    await _projects.doc(projectId).update({'name': name, 'description': description});
  }

  Future<void> deleteProject(String projectId) async {
    await _projects.doc(projectId).delete();
  }

  Future<void> removeMember({required String projectId, required String memberId}) async {
    try {
      await _projects.doc(projectId).update({
        'members': FieldValue.arrayRemove([memberId]) // arrayRemove menghapus item spesifik
      });
    } catch (e) {
      throw e.toString();
    }
  }

  Stream<ProjectModel> getProjectStream(String projectId) {
    return _projects.doc(projectId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return ProjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        throw Exception("Project not found");
      }
    });
  }
}