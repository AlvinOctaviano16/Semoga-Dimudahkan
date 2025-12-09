import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_task_app/features/task/presentation/screens/task_list_screen.dart';
import 'firebase_options.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:sync_task_app/features/task/domain/task_provider.dart';

// File: lib/features/task/domain/task_dummy_data.dart (atau file baru)

import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';
import 'package:uuid/uuid.dart'; // Import Uuid untuk ID unik dummy
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp

final List<TaskModel> dummyTasks = [
  TaskModel(
    id: const Uuid().v4(),
    projectId: 'project-testing-123',
    title: 'Design UI untuk Task List',
    description: 'Selesaikan implementasi TaskListScreen',
    status: TaskStatus.done, // Akan tampil completed (Hijau)
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
    status: TaskStatus.inProgress, // Akan tampil inProgress (Kuning/Jingga)
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
    status: TaskStatus.todo, // Akan tampil ToDo (Ungu)
    assignedToId: 'user-farid',
    proofUrl: null,
    dueDate: DateTime.now().add(const Duration(days: 14)),
    createAt: DateTime.now(),
  ),
];

final mockedTaskListStreamProvider = 
    StreamProvider.family<List<TaskModel>, String>((ref, projectId) {
  // Kita kembalikan stream yang langsung berisi data dummy
  return Stream.value(dummyTasks); 
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Uncomment baris di bawah ini setelah menjalankan 'flutterfire configure'
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Wajib membungkus aplikasi dengan ProviderScope agar Riverpod jalan
    ProviderScope(
      overrides: [
        taskListStreamProvider.overrideWith(
          (ref, projectId) {
            // Langsung kembalikan Stream dari dummyTasks yang sudah kamu buat
            return Stream.value(dummyTasks);
          },
        ),
    ],
      child: const MyApp(),
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
      // Nanti ganti ini ke LoginScreen()
      // home: const Scaffold(
      //   body: Center(child: Text("Setup Project Berhasil!")),
      // ),

      home: const TaskListScreen(projectId: 'project-testing-123'),
      debugShowCheckedModeBanner: false,
    );
  }
}