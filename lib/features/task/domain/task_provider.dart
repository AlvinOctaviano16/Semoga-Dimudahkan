import 'package:sync_task_app/features/task/data/task_repository.dart';
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskListStreamProvider=
    StreamProvider.family.autoDispose<List<TaskModel>, String>((ref,projectId){
  return ref.watch(taskRepositoryProvider).getTasksByProject(projectId);
  });


class CreateTaskNotifier extends Notifier<AsyncValue<void>>{
  @override
  AsyncValue<void> build(){
    //state awal
    return const AsyncData(null);
  }


  //Melakukan Submit Tugas Baru ke Firestore
  Future<void> submitTask({
    required TaskModel task,
  }) async{
    //state loading
    state=const AsyncLoading();
    try{
      //repository menyimpan data
      await   ref.read(taskRepositoryProvider).createTask(task);
      //state ke data (berhasil)
      state = const AsyncData(null);
    }catch(e, st){
      //state error
      state=AsyncError(e,st);
    }
  }
}

//
final createTaskNotifierProvider=
  NotifierProvider.autoDispose<CreateTaskNotifier, AsyncValue<void>>(
    CreateTaskNotifier.new
  );