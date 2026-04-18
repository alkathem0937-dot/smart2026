class TaskModel {
  final int id;
  final int lawsuitId;
  final String title;
  final String priority;
  bool isCompleted;
  final DateTime? dueDate;

  TaskModel({
    required this.id,
    required this.lawsuitId,
    required this.title,
    required this.priority,
    this.isCompleted = false,
    this.dueDate,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      lawsuitId: json['lawsuit'] ?? 0,
      title: json['title'] ?? '',
      priority: json['priority'] ?? 'medium',
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'lawsuit': lawsuitId,
      'title': title,
      'priority': priority,
      'is_completed': isCompleted,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
    };
  }
}
