import 'package:flutter/material.dart';
import 'package:sync_task_app/core/constants/app_colors.dart';
import 'package:sync_task_app/features/task/domain/task_priority.dart';

class TaskPriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const TaskPriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    
    switch (priority) {
      case TaskPriority.high:
        color = AppColors.highPriority; // Merah
        break;
      case TaskPriority.medium:
        color = AppColors.mediumPriority; // Kuning
        break;
      case TaskPriority.low:
        color = AppColors.lowPriority; // Ungu
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Background transparan
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color), // Border sesuai warna
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.displayValue,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}