/// Real-world example: Todo service contract.
///
/// This contract demonstrates a production-quality service definition
/// with comprehensive types, documentation, and edge cases.
library;

import 'package:fluttron_shared/fluttron_shared.dart';

// ============================================================================
// Models
// ============================================================================

/// Priority level for todo items.
enum TodoPriority { low, medium, high, urgent }

/// A todo item in the task management system.
///
/// This model includes all common fields you would expect in a
/// production todo application, including timestamps, completion
/// status, and categorization.
@FluttronModel()
class TodoItem {
  /// Unique identifier for the todo item.
  final String id;

  /// Title or description of the task.
  final String title;

  /// Optional detailed description.
  final String? description;

  /// Whether the task is completed.
  final bool isCompleted;

  /// Priority level.
  final String priority;

  /// List of tags for categorization.
  final List<String> tags;

  /// When the task was created.
  final DateTime createdAt;

  /// When the task was last updated (null if never updated).
  final DateTime? updatedAt;

  /// Optional due date.
  final DateTime? dueDate;

  /// Custom metadata for extensibility.
  final Map<String, dynamic> metadata;

  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    required this.metadata,
  });
}

/// Statistics about the todo list.
@FluttronModel()
class TodoStats {
  /// Total number of items.
  final int total;

  /// Number of completed items.
  final int completed;

  /// Number of pending items.
  final int pending;

  /// Items grouped by priority.
  final Map<String, int> byPriority;

  /// Items grouped by tag.
  final Map<String, int> byTag;

  const TodoStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.byPriority,
    required this.byTag,
  });
}

/// Filter options for querying todos.
@FluttronModel()
class TodoFilter {
  /// Filter by completion status (null = all).
  final bool? isCompleted;

  /// Filter by priority (null = all).
  final String? priority;

  /// Filter by tag (null = all).
  final String? tag;

  /// Filter by due date range (start).
  final DateTime? dueAfter;

  /// Filter by due date range (end).
  final DateTime? dueBefore;

  /// Search term for title/description.
  final String? searchTerm;

  const TodoFilter({
    this.isCompleted,
    this.priority,
    this.tag,
    this.dueAfter,
    this.dueBefore,
    this.searchTerm,
  });
}

// ============================================================================
// Service Contract
// ============================================================================

/// Todo management service for task tracking.
///
/// This service provides CRUD operations for todo items along with
/// filtering, statistics, and batch operations.
///
/// ## Usage Example
///
/// ```dart
/// final client = FluttronClient();
/// final todoService = TodoServiceClient(client);
///
/// // Create a new todo
/// final todo = await todoService.create(
///   title: 'Complete Fluttron documentation',
///   priority: 'high',
///   tags: ['work', 'documentation'],
/// );
///
/// // List all high-priority todos
/// final items = await todoService.list(
///   filter: TodoFilter(priority: 'high'),
/// );
/// ```
@FluttronServiceContract(namespace: 'todo')
abstract class TodoService {
  // ==========================================================================
  // CRUD Operations
  // ==========================================================================

  /// Creates a new todo item.
  ///
  /// [title] — The task title (required).
  /// [description] — Optional detailed description.
  /// [priority] — Priority level (default: 'medium').
  /// [tags] — List of tags for categorization.
  /// [dueDate] — Optional due date.
  ///
  /// Returns the created todo item with generated ID and timestamps.
  Future<TodoItem> create(
    String title, {
    String? description,
    String priority = 'medium',
    List<String> tags = const [],
    DateTime? dueDate,
  });

  /// Gets a todo item by ID.
  ///
  /// Returns null if the item doesn't exist.
  Future<TodoItem?> getById(String id);

  /// Updates an existing todo item.
  ///
  /// Only provided fields will be updated.
  /// Returns the updated item, or null if not found.
  Future<TodoItem?> update(
    String id, {
    String? title,
    String? description,
    String? priority,
    List<String>? tags,
    DateTime? dueDate,
  });

  /// Deletes a todo item.
  ///
  /// Returns true if deleted, false if not found.
  Future<bool> delete(String id);

  // ==========================================================================
  // Query Operations
  // ==========================================================================

  /// Lists todo items with optional filtering.
  ///
  /// [filter] — Filter options (all fields optional).
  /// [limit] — Maximum items to return (default: 100).
  /// [offset] — Pagination offset (default: 0).
  ///
  /// Returns items sorted by creation date (newest first).
  Future<List<TodoItem>> list({
    TodoFilter? filter,
    int limit = 100,
    int offset = 0,
  });

  /// Searches todo items by title or description.
  ///
  /// [query] — Search term.
  /// [maxResults] — Maximum items to return.
  ///
  /// Returns matching items sorted by relevance.
  Future<List<TodoItem>> search(String query, {int maxResults = 50});

  // ==========================================================================
  // Status Operations
  // ==========================================================================

  /// Marks a todo as completed.
  ///
  /// Returns the updated item, or null if not found.
  Future<TodoItem?> markCompleted(String id);

  /// Marks a todo as pending (uncompleted).
  ///
  /// Returns the updated item, or null if not found.
  Future<TodoItem?> markPending(String id);

  /// Toggles the completion status.
  ///
  /// Returns the updated item, or null if not found.
  Future<TodoItem?> toggleComplete(String id);

  // ==========================================================================
  // Batch Operations
  // ==========================================================================

  /// Marks multiple todos as completed.
  ///
  /// [ids] — List of todo IDs.
  /// Returns the number of items updated.
  Future<int> markCompletedBatch(List<String> ids);

  /// Deletes multiple todos.
  ///
  /// [ids] — List of todo IDs.
  /// Returns the number of items deleted.
  Future<int> deleteBatch(List<String> ids);

  /// Deletes all completed todos.
  ///
  /// Returns the number of items deleted.
  Future<int> deleteCompleted();

  // ==========================================================================
  // Statistics
  // ==========================================================================

  /// Gets statistics about the todo list.
  ///
  /// Returns counts by status, priority, and tags.
  Future<TodoStats> getStats();

  /// Gets the count of todos matching a filter.
  ///
  /// [filter] — Filter options.
  Future<int> count({TodoFilter? filter});

  // ==========================================================================
  // Utility
  // ==========================================================================

  /// Checks if the service is available.
  Future<bool> isAvailable();

  /// Clears all todos (use with caution).
  ///
  /// This is a destructive operation. Returns the number deleted.
  Future<int> clearAll();
}
