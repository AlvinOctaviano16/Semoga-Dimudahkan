import 'package:flutter/material.dart';
import 'package:sync_task_app/core/constants/app_colors.dart';
import 'package:sync_task_app/features/task/domain/task_status.dart';

class TaskStatusChip extends StatelessWidget{
  final TaskStatus status;

  const TaskStatusChip({super.key,required this.status});

  @override
  Widget build(BuildContext context){
    Color backgroundColor;
    Color textColor=Colors.white;

    //Status condition 
    switch(status){
      case TaskStatus.done:
        backgroundColor=AppColors.completedGreen;
        textColor=AppColors.backgroundLight;
        break;
      case TaskStatus.inProgress:
        backgroundColor=AppColors.mediumPriority;
        break;
      case TaskStatus.todo:
        backgroundColor=AppColors.lowPriority;
    }
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 4),
      decoration: BoxDecoration(
        color:backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child:Text(
        status.displayValue.toUpperCase(),
        style:TextStyle(
          color:textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}