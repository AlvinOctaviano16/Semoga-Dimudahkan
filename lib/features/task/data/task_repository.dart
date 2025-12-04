import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';

class TaskRepository {
    final FirebaseFirestore _firestore;

    TaskRepository(this._firestore);


    // Operasi Read Mendapatkan Semua daftar Tugas
    Stream<List<TaskModel>> getTasksByProject(String projectId) {
      return _firestore
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true) 
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
                .toList();
          });
    }

    //Operasi Create
    Future<void> createTask(TaskModel task){
      return _firestore.collection('task').add(task.toMap());
    }

    //Operasi Update
    //Memperbarui status tugas berdasarkan taskId
    Future<void> updateTask(String taskId, TaskStatus status){
      return _firestore
        .collection('taskId')
        .doc(taskId)
        .update({'status':status.name});
    }

    // Memperbarui URL tugas berdasarkan taskId

    Future<void> updateTaskProof(String taskId, String proofUrl){
      return _firestore
        .collection('taskId')
        .doc(taskId)
        .update({'proofUrl':proofUrl});
    }

    //Operasi Delete
    Future<void> deleteTask(String taskId){
      return _firestore.collection('task').doc(taskId).delete();
    }

    //Provider Riverpod menyediakan instance TaskRepository
    final takeRepositoryProvider=Provider<TaskRepository>((ref){
      return TaskRepository(FirebaseFirestore.instance);
    });
     


}
