import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task_model.dart';
import '../domain/task_status.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepository(this._firestore);

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

  Future<void> createTask(TaskModel task) {
    return _firestore.collection('tasks').doc(task.id).set(task.toMap());
  }

  Future<void> updateTask(String taskId, TaskStatus status) {
    final Map<String, dynamic> data = {'status': status.name};
    if (status == TaskStatus.done) {
      data['completedAt'] = Timestamp.now();
    } else {
      data['completedAt'] = null;
    }
    return _firestore.collection('tasks').doc(taskId).update(data);
  }

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

  Future<void> updateTaskDetails(TaskModel task) {
    return _firestore.collection('tasks').doc(task.id).update({
      'title': task.title,
      'description': task.description,
      'dueDate': Timestamp.fromDate(task.dueDate),
      'assignedToId': task.assignedToId,
      'priority': task.priority.name,
    });
  }

  Future<void> deleteTask(String taskId) {
    return _firestore.collection('tasks').doc(taskId).delete();
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(FirebaseFirestore.instance);
});