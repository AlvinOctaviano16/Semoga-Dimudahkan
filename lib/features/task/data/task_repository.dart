import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepository(this._firestore);

  // Read: Get All Tasks
  Stream<List<TaskModel>> getTasksByProject(String projectId) {
    return _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Create
  Future<void> createTask(TaskModel task) {
    return _firestore.collection('tasks').add(task.toMap());
  }

  // --- PERBAIKAN DI SINI ---
  // Update Status & Waktu Selesai (completedAt)
  Future<void> updateTask(String taskId, TaskStatus status) {
    final Map<String, dynamic> data = {'status': status.name};
    
    // Jika user menandai selesai (Done), simpan waktu sekarang
    if (status == TaskStatus.done) {
      data['completedAt'] = Timestamp.now();
    } else {
      // Jika user un-check (kembali ke Todo/InProgress), hapus waktu selesai
      data['completedAt'] = null;
    }

    return _firestore
        .collection('tasks')
        .doc(taskId)
        .update(data);
  }
  // -------------------------

  // Update: Submit Bukti & Selesaikan Tugas
  Future<void> submitTaskCompletion({
    required String taskId,
    required String proofUrl,
    required String comment,
  }) {
    return _firestore.collection('tasks').doc(taskId).update({
      'proofUrl': proofUrl,
      'submissionComment': comment,
      'completedAt': Timestamp.now(),
      'status': TaskStatus.done.name,
    });
  }

  // Update: Edit Detail Tugas
  Future<void> updateTaskDetails(TaskModel task) {
    return _firestore.collection('tasks').doc(task.id).update({
      'title': task.title,
      'description': task.description,
      'dueDate': Timestamp.fromDate(task.dueDate),
      'assignedToId': task.assignedToId,
      'priority': task.priority.name,
    });
  }

  // Delete
  Future<void> deleteTask(String taskId) {
    return _firestore.collection('tasks').doc(taskId).delete();
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(FirebaseFirestore.instance);
});