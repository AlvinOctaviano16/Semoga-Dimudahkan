import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';
// 1. IMPORT INI PENTING
import 'package:sync_task_app/features/task/domain/task_priority.dart'; 

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  
  // 2. TAMBAHKAN FIELD INI
  final TaskPriority priority; 
  
  final String assignedToId;
  final String? proofUrl;
  final String? submissionComment;
  final DateTime? completedAt;
  final DateTime dueDate;
  final DateTime createAt;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    
    // 3. TAMBAHKAN DI CONSTRUCTOR
    required this.priority, 
    
    required this.assignedToId,
    required this.dueDate,
    required this.createAt,
    this.proofUrl,
    this.submissionComment,
    this.completedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      projectId: map['projectId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      
      // 4. MAPPING DARI FIREBASE (JIKA KOSONG DEFAULT MEDIUM)
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      
      assignedToId: map['assignedToId'] as String,
      proofUrl: map['proofUrl'] as String?,
      submissionComment: map['submissionComment'] as String?,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createAt: (map['createAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.name,
      
      // 5. SIMPAN KE FIREBASE
      'priority': priority.name, 
      
      'assignedToId': assignedToId,
      'proofUrl': proofUrl,
      'submissionComment': submissionComment,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'dueDate': Timestamp.fromDate(dueDate),
      'createAt': Timestamp.fromDate(createAt),
    };
  }
}