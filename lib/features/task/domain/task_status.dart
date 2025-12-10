enum TaskStatus{
  todo('To Do'),
  inProgress('In Progress'),
  done('Done'),;

  final String displayValue;
  const TaskStatus(this.displayValue);
}