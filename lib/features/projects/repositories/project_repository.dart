import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

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
      String inviteCode = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      await _projects.add({
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'members': [ownerId],
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // READ
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _projects
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  // DELETE (Tambahkan ini di bawah fungsi getUserProjects)
  Future<void> deleteProject(String projectId) async {
    try {
      await _projects.doc(projectId).delete();
    } catch (e) {
      throw e.toString();
    }
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
        // Kita tidak update 'ownerId', 'createdAt', atau 'members'
        // karena itu data sensitif/tetap.
      });
    } catch (e) {
      throw e.toString();
    }
  }
}