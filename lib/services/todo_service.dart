import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo.dart';
import 'supabase_browser_client.dart';

class TodoService {
  final SupabaseBrowserClient _client;
  static const String _tableName = 'todos';

  TodoService(this._client);

  Stream<List<Todo>> subscribeToTodos() {
    return _client.stream(_tableName).map((events) =>
      events.map((json) => Todo.fromJson(json)).toList()
    );
  }

  Future<List<Todo>> getTodos() async {
    try {
      final response = await _client.from(_tableName);
      return response.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch todos: $e');
    }
  }

  Future<Todo> createTodo(String title) async {
    try {
      final user = _client.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create todos');
      }

      final data = {
        'title': title,
        'completed': false,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user.id,
      };

      final response = await _client.insert(_tableName, data);
      return Todo.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  Future<void> updateTodo(String id, {String? title, bool? completed}) async {
    try {
      final user = _client.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update todos');
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (title != null) updates['title'] = title;
      if (completed != null) updates['completed'] = completed;

      await _client.update(_tableName, updates, id);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      final user = _client.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete todos');
      }

      await _client.delete(_tableName, id);
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  Future<void> batchUpdateTodos(List<Map<String, dynamic>> updates) async {
    try {
      await _client.batchOperation(updates);
    } catch (e) {
      throw Exception('Failed to batch update todos: $e');
    }
  }
} 