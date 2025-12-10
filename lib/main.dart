import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:sync_task_app/features/task/presentation/screens/task_list_screen.dart';

// Import untuk Dummy Data
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';
import 'package:sync_task_app/features/task/domain/task_priority.dart'; // Import Priority
import 'package:uuid/uuid.dart';

// --- DUMMY DATA YANG SUDAH DIPERBAIKI ---
final List<TaskModel> dummyTasks = [
  TaskModel(
    id: const Uuid().v4(),
    projectId: 'project-testing-123',
    title: 'Design UI untuk Task List',
    description: 'Selesaikan implementasi TaskListScreen',
    status: TaskStatus.done,
    priority: TaskPriority.high, // TAMBAHKAN INI
    assignedToId: 'user-alvin',
    proofUrl: 'http://dummy.url/proof1.jpg',
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    createAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  TaskModel(
    id: const Uuid().v4(),
    projectId: 'project-testing-123',
    title: 'Implementasi Logic CRUD',
    description: 'Fokus pada TaskRepository.updateTaskStatus',
    status: TaskStatus.inProgress,
    priority: TaskPriority.medium, // TAMBAHKAN INI
    assignedToId: 'user-alvin',
    proofUrl: null,
    dueDate: DateTime.now().add(const Duration(days: 3)),
    createAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  TaskModel(
    id: const Uuid().v4(),
    projectId: 'project-testing-123',
    title: 'Buat Class Model Data Project',
    description: 'Ini bagian Farid, tapi harus dipantau!',
    status: TaskStatus.todo,
    priority: TaskPriority.low, // TAMBAHKAN INI
    assignedToId: 'user-farid',
    proofUrl: null,
    dueDate: DateTime.now().add(const Duration(days: 14)),
    createAt: DateTime.now(),
  ),
];

// Provider Mock
final mockedTaskListStreamProvider = 
    StreamProvider.family<List<TaskModel>, String>((ref, projectId) {
  return Stream.value(dummyTasks); 
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamTask App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TaskListScreen(projectId: 'project-testing-123'),
      debugShowCheckedModeBanner: false,
    );
  }
}