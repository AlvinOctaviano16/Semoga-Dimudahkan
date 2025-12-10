import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_status.dart';
import 'task_priority.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
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