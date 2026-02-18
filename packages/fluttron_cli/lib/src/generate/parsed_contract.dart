/// Data models representing parsed service contracts and models.
///
/// These models are produced by [ServiceContractParser] and consumed
/// by code generators to produce Host/Client/Model Dart code.
library;

/// Represents a parsed @FluttronServiceContract class.
class ParsedServiceContract {
  /// Creates a [ParsedServiceContract] with the given details.
  const ParsedServiceContract({
    required this.className,
    required this.namespace,
    required this.methods,
    this.documentation,
  });

  /// The Dart class name (e.g., 'WeatherService').
  final String className;

  /// The namespace from the annotation (e.g., 'weather').
  final String namespace;

  /// The methods defined in the service contract.
  final List<ParsedMethod> methods;

  /// Optional documentation comment for the service.
  final String? documentation;

  @override
  String toString() =>
      'ParsedServiceContract($className, namespace: $namespace, '
      'methods: ${methods.length})';
}

/// Represents a parsed method from a service contract.
class ParsedMethod {
  /// Creates a [ParsedMethod] with the given details.
  const ParsedMethod({
    required this.name,
    required this.parameters,
    required this.returnType,
    this.documentation,
  });

  /// The method name (e.g., 'getCurrentWeather').
  final String name;

  /// The method parameters (positional and named).
  final List<ParsedParameter> parameters;

  /// The return type (with Future unwrapped if applicable).
  final ParsedType returnType;

  /// Optional documentation comment for the method.
  final String? documentation;

  /// Whether this method has any required positional parameters.
  bool get hasRequiredPositionalParams =>
      parameters.any((p) => p.isRequired && !p.isNamed);

  /// Whether this method has any optional named parameters.
  bool get hasOptionalNamedParams =>
      parameters.any((p) => p.isNamed && p.hasDefaultValue);

  @override
  String toString() =>
      'ParsedMethod($name, params: ${parameters.length}, '
      'return: $returnType)';
}

/// Represents a parsed parameter from a method.
class ParsedParameter {
  /// Creates a [ParsedParameter] with the given details.
  const ParsedParameter({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    this.defaultValue,
  });

  /// The parameter name.
  final String name;

  /// The parameter type.
  final ParsedType type;

  /// Whether this parameter is required.
  /// For named parameters, this is false if the param has a default value.
  final bool isRequired;

  /// Whether this is a named parameter.
  final bool isNamed;

  /// The default value as a string literal (e.g., '5', "'default'").
  final String? defaultValue;

  /// Whether this parameter has a default value.
  bool get hasDefaultValue => defaultValue != null;

  @override
  String toString() =>
      'ParsedParameter($name: $type, '
      'required: $isRequired, named: $isNamed)';
}

/// Represents a parsed @FluttronModel class.
class ParsedModel {
  /// Creates a [ParsedModel] with the given details.
  const ParsedModel({
    required this.className,
    required this.fields,
    this.documentation,
  });

  /// The Dart class name (e.g., 'WeatherInfo').
  final String className;

  /// The fields defined in the model.
  final List<ParsedField> fields;

  /// Optional documentation comment for the model.
  final String? documentation;

  @override
  String toString() => 'ParsedModel($className, fields: ${fields.length})';
}

/// Represents a parsed field from a model.
class ParsedField {
  /// Creates a [ParsedField] with the given details.
  const ParsedField({
    required this.name,
    required this.type,
    this.documentation,
  });

  /// The field name.
  final String name;

  /// The field type.
  final ParsedType type;

  /// Optional documentation comment for the field.
  final String? documentation;

  @override
  String toString() => 'ParsedField($name: $type)';
}

/// Represents a parsed Dart type.
class ParsedType {
  /// Creates a [ParsedType] with the given details.
  const ParsedType({
    required this.displayName,
    required this.isNullable,
    this.typeArguments = const [],
  });

  /// The type name as it appears in source (e.g., 'String', 'List<int>').
  final String displayName;

  /// Whether this type is nullable (has '?' suffix).
  final bool isNullable;

  /// Type arguments for generic types (e.g., [int] for List<int>).
  final List<ParsedType> typeArguments;

  /// The base type name without nullability or type arguments.
  String get baseName {
    var name = displayName;
    if (name.endsWith('?')) {
      name = name.substring(0, name.length - 1);
    }
    // Remove type arguments if present
    final bracketIndex = name.indexOf('<');
    if (bracketIndex > 0) {
      name = name.substring(0, bracketIndex);
    }
    return name;
  }

  /// Whether this type is a Future.
  bool get isFuture => baseName == 'Future';

  /// Whether this is a List type.
  bool get isList => baseName == 'List';

  /// Whether this is a Map type.
  bool get isMap => baseName == 'Map';

  /// Whether this is a basic type (String, int, double, bool, DateTime).
  bool get isBasicType =>
      ['String', 'int', 'double', 'bool', 'DateTime', 'num'].contains(baseName);

  /// Whether this is void.
  bool get isVoid => baseName == 'void';

  /// Whether this is dynamic.
  bool get isDynamic => baseName == 'dynamic';

  /// The inner type for Future<T> or List<T>.
  ParsedType? get innerType =>
      typeArguments.isNotEmpty ? typeArguments.first : null;

  /// Creates a non-nullable version of this type.
  ParsedType get asNonNullable => ParsedType(
    displayName: displayName.endsWith('?')
        ? displayName.substring(0, displayName.length - 1)
        : displayName,
    isNullable: false,
    typeArguments: typeArguments,
  );

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      other is ParsedType &&
      other.displayName == displayName &&
      other.isNullable == isNullable &&
      _listEquals(other.typeArguments, typeArguments);

  @override
  int get hashCode => Object.hash(displayName, isNullable, typeArguments);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Result of parsing a contract file.
class ParsedContractFile {
  /// Creates a [ParsedContractFile] with the given contracts and models.
  const ParsedContractFile({
    this.contracts = const [],
    this.models = const [],
    this.errors = const [],
  });

  /// The service contracts found in the file.
  final List<ParsedServiceContract> contracts;

  /// The model classes found in the file.
  final List<ParsedModel> models;

  /// Any errors encountered during parsing.
  final List<String> errors;

  /// Whether parsing was successful (no errors).
  bool get isSuccess => errors.isEmpty;

  @override
  String toString() =>
      'ParsedContractFile(contracts: ${contracts.length}, '
      'models: ${models.length}, errors: ${errors.length})';
}
