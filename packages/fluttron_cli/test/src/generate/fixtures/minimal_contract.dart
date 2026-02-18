// Minimal test fixture that doesn't require fluttron_shared.
// Used for parser unit tests.

/// Mock annotation for testing - simulates @FluttronServiceContract.
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

/// Mock annotation for testing - simulates @FluttronModel.
class FluttronModel {
  const FluttronModel();
}

/// Minimal service contract for basic parsing tests.
@FluttronServiceContract(namespace: 'minimal')
abstract class MinimalService {
  Future<String> ping();
  Future<int> add(int a, int b);
}

/// Service with optional parameters.
@FluttronServiceContract(namespace: 'optional_params')
abstract class OptionalParamsService {
  Future<String> greet({String name = 'World'});
  Future<int> count({int start = 0, int step = 1});
}

/// Service with nullable types.
@FluttronServiceContract(namespace: 'nullable')
abstract class NullableService {
  Future<String?> find(String id);
  Future<void> update(String id, String? value);
}

/// Service with List and Map types.
@FluttronServiceContract(namespace: 'collections')
abstract class CollectionsService {
  Future<List<String>> getNames();
  Future<List<int>> getIds();
  Future<Map<String, dynamic>> getConfig();
  Future<void> setItems(List<String> items);
}

/// Model for testing field parsing.
@FluttronModel()
class SimpleModel {
  final String name;
  final int value;
  final bool active;

  const SimpleModel({
    required this.name,
    required this.value,
    required this.active,
  });
}

/// Model with nullable fields.
@FluttronModel()
class ModelWithNullables {
  final String id;
  final String? description;
  final int? count;

  const ModelWithNullables({required this.id, this.description, this.count});
}

/// Model with collection fields.
@FluttronModel()
class ModelWithCollections {
  final String id;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const ModelWithCollections({
    required this.id,
    required this.tags,
    required this.metadata,
  });
}
