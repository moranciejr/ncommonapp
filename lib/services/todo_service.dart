import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo.dart';

class TodoService {
  final SupabaseClient _client;
  static const String _tableName = 'todos';

  TodoService(this._client);

  Stream<List<Todo>> subscribeToTodos() {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .map((events) => events.map((json) => Todo.fromJson(json)).toList());
  }

  Future<List<Todo>> getTodos() async {
    try {
      final response = await _client.from(_tableName).select();
      final data = response as List<dynamic>?;
      if (data == null) return [];
      return data.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch todos: $e');
    }
  }

  Future<Todo> createTodo(String title) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create todos');
      }

      final data = {
        'title': title,
        'completed': false,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user.id,
      };

      final response = await _client.from(_tableName).insert(data).select().single();
      return Todo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  Future<void> updateTodo(String id, {String? title, bool? completed}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update todos');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['title'] = title;
      if (completed != null) updates['completed'] = completed;

      await _client.from(_tableName).update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete todos');
      }

      await _client.from(_tableName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  // Batch update is not natively supported; implement as needed or remove.
} 