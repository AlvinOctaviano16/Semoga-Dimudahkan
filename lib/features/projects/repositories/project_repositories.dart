import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference agar tidak ngetik ulang-ulang
  CollectionReference get _projects => _firestore.collection('projects');

  // 1. CREATE: Membuat Project Baru
  Future<void> createProject({
    required String name,
    required String description,
    required String ownerId,
  }) async {
    try {
      // Generate kode unik sederhana untuk invite (opsional)
      String inviteCode = DateTime.now().millisecondsSinceEpoch.toString().substring(8);

      await _projects.add({
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'members': [ownerId], // Owner otomatis jadi member pertama
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // 2. READ: Mengambil daftar project milik user (Stream)
  // Stream artinya data akan update real-time jika ada perubahan
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    return _projects
        .where('members', arrayContains: userId) // Query Firestore
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // 3. JOIN: Gabung Project via Kode (Kita simpan logic-nya di sini dulu)
  Future<void> joinProject(String inviteCode, String userId) async {
    // Cari project yang punya kode tersebut
    final querySnapshot = await _projects.where('inviteCode', isEqualTo: inviteCode).get();

    if (querySnapshot.docs.isEmpty) {
      throw 'Project tidak ditemukan / Kode salah';
    }

    final docId = querySnapshot.docs.first.id;

    // Update array members
    await _projects.doc(docId).update({
      'members': FieldValue.arrayUnion([userId])
    });
  }
}