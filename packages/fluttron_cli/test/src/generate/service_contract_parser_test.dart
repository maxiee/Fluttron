import 'package:test/test.dart';

import 'package:fluttron_cli/src/generate/parsed_contract.dart';
import 'package:fluttron_cli/src/generate/service_contract_parser.dart';

void main() {
  late ServiceContractParser parser;

  setUp(() {
    parser = ServiceContractParser();
  });

  group('ServiceContractParser', () {
    group('parseString', () {
      test('parses empty source without errors', () {
        final result = parser.parseString('');
        expect(result.isSuccess, isTrue);
        expect(result.contracts, isEmpty);
        expect(result.models, isEmpty);
      });

      test('parses source without contracts or models', () {
        final result = parser.parseString('''
class PlainClass {
  void method() {}
}
''');
        expect(result.isSuccess, isTrue);
        expect(result.contracts, isEmpty);
        expect(result.models, isEmpty);
      });

      test('reports parse errors for invalid syntax', () {
        final result = parser.parseString('class { }');
        expect(result.errors, isNotEmpty);
      });

      test('returns error for non-existent file', () {
        final result = parser.parseFile('/non/existent/file.dart');
        expect(result.isSuccess, isFalse);
        expect(
          result.errors,
          contains('File not found: /non/existent/file.dart'),
        );
      });
    });

    group('contract parsing', () {
      test('parses minimal service contract', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<String> ping();
}
''');
        expect(result.isSuccess, isTrue);
        expect(result.contracts, hasLength(1));

        final contract = result.contracts.first;
        expect(contract.className, equals('TestService'));
        expect(contract.namespace, equals('test'));
        expect(contract.methods, hasLength(1));

        final method = contract.methods.first;
        expect(method.name, equals('ping'));
        expect(method.parameters, isEmpty);
        expect(method.returnType.displayName, equals('Future<String>'));
      });

      test('parses contract with multiple methods', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'multi')
abstract class MultiService {
  Future<String> getName();
  Future<int> getCount();
  Future<void> reset();
}
''');
        expect(result.isSuccess, isTrue);
        expect(result.contracts, hasLength(1));

        final contract = result.contracts.first;
        expect(contract.methods, hasLength(3));
        expect(contract.methods[0].name, equals('getName'));
        expect(contract.methods[1].name, equals('getCount'));
        expect(contract.methods[2].name, equals('reset'));
      });

      test('extracts contract documentation', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

/// This is a test service.
@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<String> ping();
}
''');
        expect(result.isSuccess, isTrue);
        final contract = result.contracts.first;
        expect(contract.documentation, contains('test service'));
      });

      test('extracts method documentation', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  /// Returns a greeting.
  Future<String> greet(String name);
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;
        expect(method.documentation, contains('Returns a greeting'));
      });
    });

    group('parameter parsing', () {
      test('parses required positional parameters', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<int> add(int a, int b);
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;
        expect(method.parameters, hasLength(2));

        expect(method.parameters[0].name, equals('a'));
        expect(method.parameters[0].type.displayName, equals('int'));
        expect(method.parameters[0].isRequired, isTrue);
        expect(method.parameters[0].isNamed, isFalse);

        expect(method.parameters[1].name, equals('b'));
        expect(method.parameters[1].type.displayName, equals('int'));
        expect(method.parameters[1].isRequired, isTrue);
        expect(method.parameters[1].isNamed, isFalse);
      });

      test('parses optional named parameters with default values', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<String> greet({String name = 'World'});
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;
        expect(method.parameters, hasLength(1));

        final param = method.parameters.first;
        expect(param.name, equals('name'));
        expect(param.type.displayName, equals('String'));
        expect(param.isNamed, isTrue);
        expect(param.defaultValue, isNotNull);
      });

      test('parses multiple optional named parameters', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<void> configure({
    String host = 'localhost',
    int port = 8080,
    bool secure = true,
  });
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;
        expect(method.parameters, hasLength(3));

        expect(method.parameters[0].name, equals('host'));
        expect(method.parameters[0].defaultValue, equals("'localhost'"));

        expect(method.parameters[1].name, equals('port'));
        expect(method.parameters[1].defaultValue, equals('8080'));

        expect(method.parameters[2].name, equals('secure'));
        expect(method.parameters[2].defaultValue, equals('true'));
      });

      test('parses mixed required and optional parameters', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<void> update(String id, {String? value});
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;
        expect(method.parameters, hasLength(2));

        expect(method.parameters[0].name, equals('id'));
        expect(method.parameters[0].isRequired, isTrue);
        expect(method.parameters[0].isNamed, isFalse);

        expect(method.parameters[1].name, equals('value'));
        expect(method.parameters[1].isNamed, isTrue);
        expect(method.parameters[1].type.isNullable, isTrue);
      });
    });

    group('type parsing', () {
      test('parses basic types', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<String> getString();
  Future<int> getInt();
  Future<double> getDouble();
  Future<bool> getBool();
}
''');
        expect(result.isSuccess, isTrue);
        final methods = result.contracts.first.methods;

        expect(methods[0].returnType.baseName, equals('Future'));
        expect(methods[0].returnType.innerType?.baseName, equals('String'));

        expect(methods[1].returnType.innerType?.baseName, equals('int'));
        expect(methods[2].returnType.innerType?.baseName, equals('double'));
        expect(methods[3].returnType.innerType?.baseName, equals('bool'));
      });

      test('parses nullable types', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<String?> find(String id);
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;

        expect(method.returnType.innerType?.isNullable, isTrue);
        expect(method.returnType.innerType?.displayName, equals('String?'));
        expect(method.returnType.innerType?.baseName, equals('String'));
      });

      test('parses List types', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<List<String>> getNames();
  Future<List<int>> getIds();
}
''');
        expect(result.isSuccess, isTrue);
        final methods = result.contracts.first.methods;

        final returnType1 = methods[0].returnType;
        expect(returnType1.baseName, equals('Future'));
        expect(returnType1.innerType?.baseName, equals('List'));
        expect(returnType1.innerType?.innerType?.baseName, equals('String'));

        final returnType2 = methods[1].returnType;
        expect(returnType2.innerType?.baseName, equals('List'));
        expect(returnType2.innerType?.innerType?.baseName, equals('int'));
      });

      test('parses Map types', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<Map<String, dynamic>> getConfig();
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;

        final returnType = method.returnType;
        expect(returnType.baseName, equals('Future'));
        expect(returnType.innerType?.baseName, equals('Map'));
      });

      test('parses void return type', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<void> doSomething();
}
''');
        expect(result.isSuccess, isTrue);
        final method = result.contracts.first.methods.first;

        expect(method.returnType.innerType?.isVoid, isTrue);
      });
    });

    group('model parsing', () {
      test('parses simple model', () {
        final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

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
''');
        expect(result.isSuccess, isTrue);
        expect(result.models, hasLength(1));

        final model = result.models.first;
        expect(model.className, equals('SimpleModel'));
        expect(model.fields, hasLength(3));

        expect(model.fields[0].name, equals('name'));
        expect(model.fields[0].type.displayName, equals('String'));

        expect(model.fields[1].name, equals('value'));
        expect(model.fields[1].type.displayName, equals('int'));

        expect(model.fields[2].name, equals('active'));
        expect(model.fields[2].type.displayName, equals('bool'));
      });

      test('parses model with nullable fields', () {
        final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

@FluttronModel()
class NullableModel {
  final String id;
  final String? description;
  final int? count;

  const NullableModel({
    required this.id,
    this.description,
    this.count,
  });
}
''');
        expect(result.isSuccess, isTrue);
        final model = result.models.first;

        expect(model.fields[0].type.isNullable, isFalse);
        expect(model.fields[1].type.isNullable, isTrue);
        expect(model.fields[2].type.isNullable, isTrue);
      });

      test('parses model with collection fields', () {
        final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

@FluttronModel()
class CollectionModel {
  final String id;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const CollectionModel({
    required this.id,
    required this.tags,
    required this.metadata,
  });
}
''');
        expect(result.isSuccess, isTrue);
        final model = result.models.first;

        expect(model.fields[1].type.isList, isTrue);
        expect(model.fields[2].type.isMap, isTrue);
      });

      test('parses multiple models', () {
        final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

@FluttronModel()
class FirstModel {
  final String id;
  const FirstModel({required this.id});
}

@FluttronModel()
class SecondModel {
  final String name;
  const SecondModel({required this.name});
}
''');
        expect(result.isSuccess, isTrue);
        expect(result.models, hasLength(2));

        expect(result.models[0].className, equals('FirstModel'));
        expect(result.models[1].className, equals('SecondModel'));
      });

      test('extracts model documentation', () {
        final result = parser.parseString('''
class FluttronModel {
  const FluttronModel();
}

/// A user model.
@FluttronModel()
class UserModel {
  final String name;
  const UserModel({required this.name});
}
''');
        expect(result.isSuccess, isTrue);
        final model = result.models.first;
        expect(model.documentation, contains('user model'));
      });
    });

    group('combined parsing', () {
      test('parses both contract and models in same file', () {
        final result = parser.parseString('''
class FluttronServiceContract {
  final String namespace;
  const FluttronServiceContract({required this.namespace});
}

class FluttronModel {
  const FluttronModel();
}

@FluttronServiceContract(namespace: 'test')
abstract class TestService {
  Future<User> getUser(String id);
}

@FluttronModel()
class User {
  final String id;
  final String name;
  const User({required this.id, required this.name});
}
''');
        expect(result.isSuccess, isTrue);
        expect(result.contracts, hasLength(1));
        expect(result.models, hasLength(1));

        expect(result.contracts.first.className, equals('TestService'));
        expect(result.models.first.className, equals('User'));
      });
    });

    group('ParsedType', () {
      test('identifies Future types', () {
        const type = ParsedType(
          displayName: 'Future<String>',
          isNullable: false,
          typeArguments: [ParsedType(displayName: 'String', isNullable: false)],
        );
        expect(type.isFuture, isTrue);
        expect(type.innerType?.baseName, equals('String'));
      });

      test('identifies List types', () {
        const type = ParsedType(
          displayName: 'List<int>',
          isNullable: false,
          typeArguments: [ParsedType(displayName: 'int', isNullable: false)],
        );
        expect(type.isList, isTrue);
        expect(type.innerType?.baseName, equals('int'));
      });

      test('identifies nullable types', () {
        const type = ParsedType(displayName: 'String?', isNullable: true);
        expect(type.isNullable, isTrue);
        expect(type.baseName, equals('String'));
      });

      test('identifies basic types', () {
        expect(
          const ParsedType(
            displayName: 'String',
            isNullable: false,
          ).isBasicType,
          isTrue,
        );
        expect(
          const ParsedType(displayName: 'int', isNullable: false).isBasicType,
          isTrue,
        );
        expect(
          const ParsedType(
            displayName: 'CustomType',
            isNullable: false,
          ).isBasicType,
          isFalse,
        );
      });

      test('creates non-nullable version', () {
        const type = ParsedType(displayName: 'String?', isNullable: true);
        final nonNullable = type.asNonNullable;
        expect(nonNullable.isNullable, isFalse);
        expect(nonNullable.displayName, equals('String'));
      });
    });
  });
}
