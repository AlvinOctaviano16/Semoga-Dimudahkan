import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task_model.dart';

final taskListStreamProvider =
    StreamProvider.family.autoDispose<List<TaskModel>, String>((ref, projectId) {
  return ref.watch(taskRepositoryProvider).getTasksByProject(projectId);
});

class CreateTaskNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submitTask({required TaskModel task}) async {
    state = const AsyncLoading();
    try {
      await ref.read(taskRepositoryProvider).createTask(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> editTask({required TaskModel task}) async {
    state = const AsyncLoading();
    try {
      await ref.read(taskRepositoryProvider).updateTaskDetails(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final createTaskNotifierProvider =
    NotifierProvider.autoDispose<CreateTaskNotifier, AsyncValue<void>>(
  CreateTaskNotifier.new,
);

class FilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setFilter(String newFilter) => state = newFilter;
}

final filterTypeProvider = NotifierProvider.autoDispose<FilterNotifier, String>(
  FilterNotifier.new,
);