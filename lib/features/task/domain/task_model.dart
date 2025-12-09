import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final String assignedToId;
  final String? proofUrl;
  final DateTime dueDate;
  final DateTime createAt;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    this.proofUrl,
    required this.assignedToId,
    required this.dueDate,
    required this.createAt,
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
    proofUrl: map['proofUrl'] as String?,
    assignedToId: map['assignedToId'] as String,
    dueDate: (map['dueDate'] as Timestamp).toDate(), 
    createAt: (map['createAt'] as Timestamp).toDate(),
    // -------------------------
  );
}

  Map<String,dynamic> toMap(){
    return{
      'projectId':projectId,
      'title':title,
      'description':description,
      'proofUrl':proofUrl,
      'assignedToId':assignedToId,
      'status':status.name,
      'dueDate':Timestamp.fromDate(dueDate),
      'createAt':Timestamp.fromDate(createAt),
    };
  }
}