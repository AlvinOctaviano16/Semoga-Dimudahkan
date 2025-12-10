import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';

// Provider Repository
final projectRepositoryProvider = Provider((ref) => ProjectRepository());

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _projects => _firestore.collection('projects');

  // CREATE
  Future<void> createProject({
    required String name,
    required String description,
    required String ownerId,
  }) async {
    try {
      // Generate random invite code
      String inviteCode = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      
      await _projects.add({
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'members': [ownerId], // Owner is automatically a member
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // READ (Get Projects for a specific User)
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _projects
        .where('members', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // UPDATE
  Future<void> updateProject({
    required String projectId,
    required String name,
    required String description,
  }) async {
    try {
      await _projects.doc(projectId).update({
        'name': name,
        'description': description,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // DELETE
  Future<void> deleteProject(String projectId) async {
    try {
      await _projects.doc(projectId).delete();
    } catch (e) {
      throw e.toString();
    }
  }
}