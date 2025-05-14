class Todo {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;

  Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.userId,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 