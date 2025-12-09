import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sync_task_app/core/constants/app_colors.dart';
import 'package:sync_task_app/features/task/domain/task_model.dart';
import 'package:sync_task_app/features/task/domain/task_provider.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';
import 'package:sync_task_app/features/task/presentation/widgets/task_status_chip.dart';

class TaskListScreen extends ConsumerWidget{
  final String projectId;
  const TaskListScreen({super.key,required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    //dummy watch
    final tasksAsync = ref.watch(taskListStreamProvider(projectId));
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      //  --- 2A : App Bar ---
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation:0,
        title:const Text(
          'My task',
          style : TextStyle(
            color:AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        actions:[
          IconButton(
            icon:const Icon(Icons.sort, color:AppColors.primaryText),
            onPressed: () {},
          ),
        ],
      ),

      // --- 2B : Body Placeholder ---
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTabs(),
          Expanded(
            // Logika Async Riverpod
            child:tasksAsync.when(
              loading:()=> const Center(child:CircularProgressIndicator(color:AppColors.primaryBlue)),
              error:(err,stack) => Center(child:Text('Error loading tasks : $err')),
              data : (tasks){
                if(tasks.isEmpty){
                  return const Center(child: Text('Belum ada tugas di project ini'));
                }
                return ListView.builder(
                  itemCount:tasks.length,
                  itemBuilder:(context,index){
                    final task = tasks[index];
                    return _buildTaskItem(context, task);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // --- 2C : Floating Action Button ---
      floatingActionButtonLocation:FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryBlue,
        shape:CircleBorder(),
        child:const Icon(Icons.add, color:Colors.white , size:30),
      ),
    );
  }
  

  // Deretan Tombol Filter
  Widget _buildFilterTabs(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:16.0,vertical:8.0),
      child:Row(
        children: [
          _filterButton('All', isActive: true),
          const SizedBox(width:8),
          _filterButton('Complete'),
          const SizedBox(width:8),
          _filterButton('Pending'),
        ],
      ),
    );
  }

  // kostum widget untuk tombol filter
  Widget _filterButton(String text, {bool isActive=false}){
    return Container(
      padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
      decoration: BoxDecoration(
        color:isActive ? AppColors.primaryBlue : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border:Border.all(
          color:isActive ? AppColors.primaryBlue : AppColors.dividerColor,
        ),
      ),
      child:Text(
        text,
        style: TextStyle(
          color:isActive ? Colors.white : AppColors.secondaryText,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal, 
        ),
      ),
    );
  }
  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    //Mengecek apakah task sudah selesai untuk styling coretan
    final bool isCompleted=task.status==TaskStatus.done;
    return Column(
      children: [
        ListTile(
          title: Text(
            task.title,
            style:TextStyle(
              color:AppColors.primaryText,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle:Text(
            task.description,
            style: const TextStyle(color:AppColors.secondaryText),
          ),
          
          //Integrasi task_status_chip
          trailing:TaskStatusChip(status:task.status),
          onTap:(){
            // Navigasi ke TaskDetailScreen
          },
        ),
        const Divider(height:1, color:AppColors.dividerColor),
      ],
    );
  }

}