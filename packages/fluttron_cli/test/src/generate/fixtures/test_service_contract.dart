/// Test fixture: comprehensive service contract with various edge cases.
library;

import 'package:fluttron_shared/fluttron_shared.dart';

/// Comprehensive service with all type variations for testing the parser.
@FluttronServiceContract(namespace: 'test_service')
abstract class TestService {
  /// Basic method with no parameters.
  Future<bool> noParams();

  /// Method with single required positional parameter.
  Future<String> singleRequired(String name);

  /// Method with multiple required positional parameters.
  Future<int> multipleRequired(String name, int count, double value);

  /// Method with optional named parameter with default value.
  Future<String> withDefaultValue(String name, {int count = 5});

  /// Method with nullable return type.
  Future<String?> nullableReturn(String id);

  /// Method with nullable parameter.
  Future<void> nullableParam(String? optionalName);

  /// Method with List return type.
  Future<List<String>> listReturn();

  /// Method with List parameter.
  Future<void> listParam(List<int> ids);

  /// Method with nested List return type.
  Future<List<List<String>>> nestedListReturn();

  /// Method with Map return type.
  Future<Map<String, dynamic>> mapReturn();

  /// Method with Map parameter.
  Future<void> mapParam(Map<String, dynamic> data);

  /// Method with custom model return type.
  Future<TestModel> modelReturn();

  /// Method with custom model parameter.
  Future<void> modelParam(TestModel model);

  /// Method with List of custom models.
  Future<List<TestModel>> listModelReturn();

  /// Method with multiple optional named parameters.
  Future<String> multipleOptional({
    String name = 'default',
    int count = 1,
    bool flag = true,
  });

  /// Method with mixed required and optional.
  Future<void> mixedParams(String required, {String? optional});

  /// Async void method.
  Future<void> asyncVoid();

  /// Method with DateTime type.
  Future<DateTime> getDateTime();

  /// Method with DateTime parameter.
  Future<void> setDateTime(DateTime timestamp);
}

/// Test model class with various field types.
@FluttronModel()
class TestModel {
  final String name;
  final int count;
  final double value;
  final bool flag;
  final DateTime timestamp;
  final String? nullableField;
  final List<String> listField;
  final Map<String, dynamic> mapField;

  const TestModel({
    required this.name,
    required this.count,
    required this.value,
    required this.flag,
    required this.timestamp,
    this.nullableField,
    required this.listField,
    required this.mapField,
  });
}

/// Second model for testing multiple models in one file.
@FluttronModel()
class AnotherModel {
  final String id;
  final String description;

  const AnotherModel({required this.id, required this.description});
}
