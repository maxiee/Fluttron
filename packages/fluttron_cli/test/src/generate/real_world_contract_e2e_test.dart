import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:fluttron_cli/src/generate/client_service_generator.dart';
import 'package:fluttron_cli/src/generate/host_service_generator.dart';
import 'package:fluttron_cli/src/generate/model_generator.dart';
import 'package:fluttron_cli/src/generate/service_contract_parser.dart';

/// End-to-end tests for real-world contract scenarios.
///
/// These tests validate that the code generator handles
/// production-quality contracts correctly.
void main() {
  late ServiceContractParser parser;
  late HostServiceGenerator hostGenerator;
  late ClientServiceGenerator clientGenerator;
  late ModelGenerator modelGenerator;

  setUp(() {
    parser = ServiceContractParser();
    hostGenerator = const HostServiceGenerator(
      generatedBy: 'fluttron generate services',
      sourceFile: 'real_world_todo_contract.dart',
    );
    clientGenerator = const ClientServiceGenerator(
      generatedBy: 'fluttron generate services',
      sourceFile: 'real_world_todo_contract.dart',
    );
    modelGenerator = const ModelGenerator(
      generatedBy: 'fluttron generate services',
      sourceFile: 'real_world_todo_contract.dart',
    );
  });

  group('Real-World Todo Contract E2E', () {
    late String contractPath;

    setUpAll(() {
      contractPath = p.join(
        Directory.current.path,
        'test/src/generate/fixtures/real_world_todo_contract.dart',
      );
    });

    test('parses real-world contract without errors', () {
      final result = parser.parseFile(contractPath);

      expect(result.isSuccess, isTrue, reason: result.errors.join('\n'));
      expect(result.contracts, hasLength(1));
      expect(result.models, hasLength(3));
    });

    test('extracts TodoService contract correctly', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      expect(contract.className, equals('TodoService'));
      expect(contract.namespace, equals('todo'));

      // Should have all CRUD + Query + Status + Batch + Stats + Utility methods
      expect(contract.methods.length, greaterThanOrEqualTo(15));

      // Check documentation is preserved
      expect(contract.documentation, contains('Todo management service'));
    });

    test('extracts all models correctly', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final modelNames = result.models.map((m) => m.className).toList();
      expect(modelNames, containsAll(['TodoItem', 'TodoStats', 'TodoFilter']));
    });

    test('TodoItem model has all fields with correct types', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final todoItem = result.models.firstWhere(
        (m) => m.className == 'TodoItem',
      );

      expect(todoItem.fields.length, equals(10));

      // Check required fields
      expect(todoItem.fields.any((f) => f.name == 'id'), isTrue);
      expect(todoItem.fields.any((f) => f.name == 'title'), isTrue);
      expect(todoItem.fields.any((f) => f.name == 'isCompleted'), isTrue);
      expect(todoItem.fields.any((f) => f.name == 'createdAt'), isTrue);

      // Check nullable fields
      final descriptionField = todoItem.fields.firstWhere(
        (f) => f.name == 'description',
      );
      expect(descriptionField.type.isNullable, isTrue);

      // Check DateTime field
      final createdAtField = todoItem.fields.firstWhere(
        (f) => f.name == 'createdAt',
      );
      expect(createdAtField.type.baseName, equals('DateTime'));

      // Check List field
      final tagsField = todoItem.fields.firstWhere((f) => f.name == 'tags');
      expect(tagsField.type.isList, isTrue);

      // Check Map field
      final metadataField = todoItem.fields.firstWhere(
        (f) => f.name == 'metadata',
      );
      expect(metadataField.type.isMap, isTrue);
    });

    test('generates host code for TodoService', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      final code = hostGenerator.generate(contract);

      // Header
      expect(code, contains('// GENERATED CODE — DO NOT MODIFY BY HAND'));
      expect(code, contains('abstract class TodoServiceBase'));

      // Namespace
      expect(code, contains("String get namespace => 'todo';"));

      // All methods should have case entries
      expect(code, contains("case 'create'"));
      expect(code, contains("case 'getById'"));
      expect(code, contains("case 'update'"));
      expect(code, contains("case 'delete'"));
      expect(code, contains("case 'list'"));
      expect(code, contains("case 'search'"));
      expect(code, contains("case 'markCompleted'"));
      expect(code, contains("case 'markPending'"));
      expect(code, contains("case 'toggleComplete'"));
      expect(code, contains("case 'markCompletedBatch'"));
      expect(code, contains("case 'deleteBatch'"));
      expect(code, contains("case 'deleteCompleted'"));
      expect(code, contains("case 'getStats'"));
      expect(code, contains("case 'count'"));
      expect(code, contains("case 'isAvailable'"));
      expect(code, contains("case 'clearAll'"));

      // Default case
      expect(code, contains('METHOD_NOT_FOUND'));

      // Abstract method declarations
      expect(code, contains('Future<TodoItem> create'));
      expect(code, contains('Future<TodoItem?> getById'));
      expect(code, contains('Future<TodoItem?> update'));
      expect(code, contains('Future<bool> delete'));
      expect(code, contains('Future<List<TodoItem>> list'));
      expect(code, contains('Future<TodoStats> getStats'));
      expect(code, contains('Future<int> count'));

      // Documentation preserved
      expect(code, contains('/// Creates a new todo item.'));
    });

    test('generates client code for TodoService', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      final code = clientGenerator.generate(contract);

      // Header
      expect(code, contains('// GENERATED CODE — DO NOT MODIFY BY HAND'));
      expect(code, contains('class TodoServiceClient'));

      // Constructor
      expect(code, contains('TodoServiceClient(this._client);'));
      expect(code, contains('final FluttronClient _client;'));

      // All methods should have invoke calls
      expect(code, contains("'todo.create'"));
      expect(code, contains("'todo.getById'"));
      expect(code, contains("'todo.update'"));
      expect(code, contains("'todo.delete'"));
      expect(code, contains("'todo.list'"));
      expect(code, contains("'todo.getStats'"));

      // Nullable return handling
      expect(code, contains('Future<TodoItem?> getById'));
      expect(code, contains('== null ? null :'));

      // List return handling
      expect(code, contains('Future<List<TodoItem>> list'));
      expect(code, contains('(result as List)'));

      // Documentation preserved
      expect(code, contains('/// Creates a new todo item.'));
    });

    test('generates model code for TodoItem', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final todoItem = result.models.firstWhere(
        (m) => m.className == 'TodoItem',
      );
      final code = modelGenerator.generate(todoItem);

      // Header
      expect(code, contains('// GENERATED CODE — DO NOT MODIFY BY HAND'));
      expect(code, contains('class TodoItem'));

      // All fields
      expect(code, contains('final String id;'));
      expect(code, contains('final String title;'));
      expect(code, contains('final String? description;'));
      expect(code, contains('final bool isCompleted;'));
      expect(code, contains('final String priority;'));
      expect(code, contains('final List<String> tags;'));
      expect(code, contains('final DateTime createdAt;'));
      expect(code, contains('final DateTime? updatedAt;'));
      expect(code, contains('final DateTime? dueDate;'));
      expect(code, contains('final Map<String, dynamic> metadata;'));

      // Constructor
      expect(code, contains('const TodoItem({'));
      expect(code, contains('required this.id,'));
      expect(code, contains('this.description,')); // nullable, not required

      // fromMap
      expect(code, contains('factory TodoItem.fromMap'));
      expect(code, contains("map['id'] as String"));
      expect(code, contains("map['description'] == null ? null"));
      expect(code, contains("DateTime.parse(map['createdAt']"));
      expect(code, contains("(map['tags'] as List).map((e) => e as String)"));

      // toMap
      expect(code, contains('Map<String, dynamic> toMap()'));
      expect(code, contains("'id': id,"));
      expect(code, contains("'createdAt': createdAt.toIso8601String()"));
      expect(code, contains("'description': description == null ? null"));
    });

    test('handles default parameter values in create method', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      final createMethod = contract.methods.firstWhere(
        (m) => m.name == 'create',
      );

      // Check default values are captured
      final priorityParam = createMethod.parameters.firstWhere(
        (p) => p.name == 'priority',
      );
      expect(priorityParam.hasDefaultValue, isTrue);
      expect(priorityParam.defaultValue, contains('medium'));

      final tagsParam = createMethod.parameters.firstWhere(
        (p) => p.name == 'tags',
      );
      expect(tagsParam.hasDefaultValue, isTrue);
      expect(tagsParam.defaultValue, contains('const []'));
    });

    test('handles nullable model parameter in list method', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      final listMethod = contract.methods.firstWhere((m) => m.name == 'list');

      final filterParam = listMethod.parameters.firstWhere(
        (p) => p.name == 'filter',
      );
      expect(filterParam.type.isNullable, isTrue);
    });

    test('handles Map<String, int> field in TodoStats', () {
      final result = parser.parseFile(contractPath);
      expect(result.isSuccess, isTrue);

      final todoStats = result.models.firstWhere(
        (m) => m.className == 'TodoStats',
      );

      final byPriorityField = todoStats.fields.firstWhere(
        (f) => f.name == 'byPriority',
      );
      expect(byPriorityField.type.isMap, isTrue);

      final code = modelGenerator.generate(todoStats);
      // Note: The generator currently treats all Maps as Map<String, dynamic>
      // for JSON compatibility. The field type is preserved, but fromMap
      // uses Map<String, dynamic>.from for deserialization.
      expect(code, contains('final Map<String, int> byPriority;'));
      expect(
        code,
        contains("Map<String, dynamic>.from(map['byPriority'] as Map)"),
      );
    });
  });

  group('Edge Cases', () {
    test('handles service with only void methods', () {
      final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'events')
abstract class EventService {
  Future<void> emit(String event);
  Future<void> reset();
}
''');
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      final hostCode = hostGenerator.generate(contract);
      final clientCode = clientGenerator.generate(contract);

      // Host should have return {}; for void methods
      expect(hostCode, contains('return {};'));

      // Client should not have return statement for void
      expect(clientCode, isNot(contains('return result')));
    });

    test('handles deeply nested List types', () {
      final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

@FluttronModel()
class NestedModel {
  final List<List<Map<String, dynamic>>> nestedData;

  const NestedModel({required this.nestedData});
}
''');
      expect(result.isSuccess, isTrue);

      final model = result.models.first;
      final code = modelGenerator.generate(model);

      // Should generate nested map expressions
      expect(code, contains('List<List<Map<String, dynamic>>>'));
    });

    test('handles model with all nullable fields', () {
      final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

@FluttronModel()
class OptionalModel {
  final String? name;
  final int? count;
  final DateTime? timestamp;

  const OptionalModel({this.name, this.count, this.timestamp});
}
''');
      expect(result.isSuccess, isTrue);

      final model = result.models.first;
      final code = modelGenerator.generate(model);

      // All fields should be optional in constructor
      expect(code, contains('this.name,'));
      expect(code, contains('this.count,'));
      expect(code, contains('this.timestamp,'));

      // No 'required' should appear
      expect(code, isNot(contains('required')));
    });

    test('handles method with many optional parameters', () {
      final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'config')
abstract class ConfigService {
  Future<void> configure({
    String host = 'localhost',
    int port = 8080,
    bool ssl = false,
    int timeout = 30,
    int retries = 3,
    String apiKey = '',
  });
}
''');
      expect(result.isSuccess, isTrue);

      final contract = result.contracts.first;
      final hostCode = hostGenerator.generate(contract);
      final clientCode = clientGenerator.generate(contract);

      // All default values should be preserved
      expect(hostCode, contains("'localhost'"));
      expect(hostCode, contains('8080'));
      expect(hostCode, contains('false'));
      expect(hostCode, contains('30'));
      expect(hostCode, contains('3'));
      expect(hostCode, contains("''"));

      // Client should have all params with defaults
      expect(clientCode, contains("String host = 'localhost'"));
      expect(clientCode, contains('int port = 8080'));
      expect(clientCode, contains('bool ssl = false'));
    });
  });
}
