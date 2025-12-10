import 'package:sync_task_app/features/task/data/task_repository.dart';
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Provider Stream untuk List Task
// StreamProvider masih didukung penuh di v3
final taskListStreamProvider =
    StreamProvider.family.autoDispose<List<TaskModel>, String>((ref, projectId) {
  return ref.watch(taskRepositoryProvider).getTasksByProject(projectId);
});

// 2. Notifier untuk Create Task
// PERUBAHAN V3: Gunakan 'Notifier' biasa (AutoDisposeNotifier sudah dihapus/merged)
class CreateTaskNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  // Submit tugas baru
  Future<void> submitTask({
    required TaskModel task,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(taskRepositoryProvider).createTask(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  //Fungsi untuk mengedit tugas
  Future<void> editTask({required TaskModel task}) async {
    state = const AsyncLoading();
    try {
      // Panggil fungsi update di repository
      await ref.read(taskRepositoryProvider).updateTaskDetails(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// Definisikan autoDispose DI SINI (di provider-nya)
final createTaskNotifierProvider =
    NotifierProvider.autoDispose<CreateTaskNotifier, AsyncValue<void>>(
  CreateTaskNotifier.new,
);

// 3. Provider untuk Filter
// PERUBAHAN V3: StateProvider dianggap legacy. Gunakan Notifier sederhana.
class FilterNotifier extends Notifier<String> {
  @override
  String build() {
    return 'All'; // Nilai awal
  }

  // Fungsi mengubah filter (tidak perlu pakai 'state.notifier' lagi di UI nanti, cukup panggil method ini)
  void setFilter(String newFilter) {
    state = newFilter;
  }
}

final filterTypeProvider = NotifierProvider.autoDispose<FilterNotifier, String>(
  FilterNotifier.new,
);