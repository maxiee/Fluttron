import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart' as analyzer;
import 'package:analyzer/dart/ast/ast.dart';

import 'parsed_contract.dart';

/// Parser for Fluttron service contract files.
///
/// Uses the Dart analyzer to parse @FluttronServiceContract and @FluttronModel
/// annotated classes and extract method signatures and field definitions.
class ServiceContractParser {
  /// Parses a Dart source file and extracts service contracts and models.
  ///
  /// [filePath] must be an absolute path to a valid Dart source file.
  ///
  /// Returns a [ParsedContractFile] containing all found contracts, models,
  /// and any errors encountered during parsing.
  ParsedContractFile parseFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return ParsedContractFile(errors: ['File not found: $filePath']);
    }

    try {
      final parseResult = analyzer.parseFile(
        path: filePath,
        featureSet: FeatureSet.latestLanguageVersion(),
      );

      return _processParseResult(parseResult.unit, parseResult.errors);
    } catch (e) {
      return ParsedContractFile(errors: ['Failed to parse file: $e']);
    }
  }

  /// Parses a Dart source string and extracts service contracts and models.
  ///
  /// [source] is the Dart source code to parse.
  /// [filePath] is optional and used for error messages.
  ///
  /// Returns a [ParsedContractFile] containing all found contracts, models,
  /// and any errors encountered during parsing.
  ParsedContractFile parseString(String source, {String? filePath}) {
    try {
      final parseResult = analyzer.parseString(
        content: source,
        path: filePath ?? 'fluttron_contract.dart',
        featureSet: FeatureSet.latestLanguageVersion(),
      );
      return _processParseResult(parseResult.unit, parseResult.errors);
    } catch (e) {
      return ParsedContractFile(errors: ['Failed to parse source: $e']);
    }
  }

  /// Process the parse result and extract contracts and models.
  ParsedContractFile _processParseResult(
    CompilationUnit unit,
    List<dynamic> parseErrors,
  ) {
    final errors = <String>[];
    final contracts = <ParsedServiceContract>[];
    final models = <ParsedModel>[];

    // Collect parse errors
    for (final error in parseErrors) {
      errors.add('Parse error at ${error.offset}: ${error.message}');
    }

    // Process compilation unit
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        final contract = _parseServiceContract(declaration);
        if (contract != null) {
          contracts.add(contract);
        }

        final model = _parseModel(declaration);
        if (model != null) {
          models.add(model);
        }
      }
    }

    return ParsedContractFile(
      contracts: contracts,
      models: models,
      errors: errors,
    );
  }

  /// Parses a class declaration as a @FluttronServiceContract.
  ///
  /// Returns null if the class doesn't have the annotation.
  ParsedServiceContract? _parseServiceContract(ClassDeclaration classDecl) {
    final annotation = _findAnnotation(classDecl, 'FluttronServiceContract');
    if (annotation == null) return null;

    // Extract namespace from annotation
    final namespace = _extractNamespaceFromAnnotation(annotation);
    if (namespace == null) {
      return null;
    }

    // Extract methods
    final methods = <ParsedMethod>[];
    for (final member in classDecl.members) {
      if (member is MethodDeclaration) {
        final method = _parseMethod(member);
        if (method != null) {
          methods.add(method);
        }
      }
    }

    return ParsedServiceContract(
      className: classDecl.namePart.typeName.lexeme,
      namespace: namespace,
      methods: methods,
      documentation: _extractDocumentation(classDecl.documentationComment),
    );
  }

  /// Parses a class declaration as a @FluttronModel.
  ///
  /// Returns null if the class doesn't have the annotation.
  ParsedModel? _parseModel(ClassDeclaration classDecl) {
    final annotation = _findAnnotation(classDecl, 'FluttronModel');
    if (annotation == null) return null;

    // Extract fields
    final fields = <ParsedField>[];
    for (final member in classDecl.members) {
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          final field = _parseField(variable, member.fields.type);
          if (field != null) {
            fields.add(field);
          }
        }
      }
    }

    return ParsedModel(
      className: classDecl.namePart.typeName.lexeme,
      fields: fields,
      documentation: _extractDocumentation(classDecl.documentationComment),
    );
  }

  /// Parses a method declaration.
  ParsedMethod? _parseMethod(MethodDeclaration method) {
    // Skip non-abstract methods (implementations)
    if (!method.isAbstract) return null;

    final parameters = <ParsedParameter>[];

    // Parse formal parameters
    final paramList = method.parameters;
    if (paramList != null) {
      for (final param in paramList.parameters) {
        if (param is SimpleFormalParameter) {
          parameters.add(_parseSimpleParameter(param));
        } else if (param is DefaultFormalParameter) {
          parameters.add(_parseDefaultParameter(param));
        } else if (param is FieldFormalParameter) {
          // Skip field formal parameters (this.x)
          continue;
        }
      }
    }

    // Parse return type
    final returnType = _parseType(method.returnType);

    return ParsedMethod(
      name: method.name.lexeme,
      parameters: parameters,
      returnType: returnType,
      documentation: _extractDocumentation(method.documentationComment),
    );
  }

  /// Parses a simple formal parameter.
  ParsedParameter _parseSimpleParameter(SimpleFormalParameter param) {
    final type = _parseType(param.type);
    final isNamed = param.isNamed;
    final isRequired = param.requiredKeyword != null;

    return ParsedParameter(
      name: param.name?.lexeme ?? '',
      type: type,
      isRequired: isRequired || (!isNamed && !param.isOptionalPositional),
      isNamed: isNamed,
    );
  }

  /// Parses a default formal parameter.
  ParsedParameter _parseDefaultParameter(DefaultFormalParameter param) {
    final innerParam = param.parameter;
    ParsedType type;
    String name;

    if (innerParam is SimpleFormalParameter) {
      type = _parseType(innerParam.type);
      name = innerParam.name?.lexeme ?? '';
    } else {
      type = const ParsedType(displayName: 'dynamic', isNullable: true);
      name = '';
    }

    // Extract default value
    String? defaultValue;
    if (param.defaultValue != null) {
      defaultValue = _extractDefaultValue(param.defaultValue!);
    }

    return ParsedParameter(
      name: name,
      type: type,
      isRequired: param.requiredKeyword != null,
      isNamed: param.isNamed,
      defaultValue: defaultValue,
    );
  }

  /// Extracts the default value as a string literal.
  String? _extractDefaultValue(Expression expr) {
    return expr.toSource();
  }

  /// Parses a field from a variable declaration.
  ParsedField? _parseField(VariableDeclaration variable, TypeAnnotation? type) {
    return ParsedField(name: variable.name.lexeme, type: _parseType(type));
  }

  /// Parses a type annotation into a ParsedType.
  ParsedType _parseType(TypeAnnotation? type) {
    if (type == null) {
      return const ParsedType(displayName: 'dynamic', isNullable: false);
    }

    final source = type.toSource();
    final isNullable = source.endsWith('?');

    // Parse type arguments for generics
    final typeArguments = <ParsedType>[];

    if (type is NamedType && type.typeArguments != null) {
      for (final arg in type.typeArguments!.arguments) {
        typeArguments.add(_parseType(arg));
      }
    }

    return ParsedType(
      displayName: source,
      isNullable: isNullable,
      typeArguments: typeArguments,
    );
  }

  /// Finds an annotation by name on a class declaration.
  Annotation? _findAnnotation(ClassDeclaration classDecl, String name) {
    for (final metadata in classDecl.metadata) {
      final nameNode = metadata.name;
      if (nameNode is SimpleIdentifier && nameNode.name == name) {
        return metadata;
      } else if (nameNode is PrefixedIdentifier &&
          nameNode.identifier.name == name) {
        return metadata;
      }
    }
    return null;
  }

  /// Extracts the namespace from a FluttronServiceContract annotation.
  String? _extractNamespaceFromAnnotation(Annotation annotation) {
    final arguments = annotation.arguments;
    if (arguments == null) return null;

    for (final arg in arguments.arguments) {
      if (arg is NamedExpression && arg.name.label.name == 'namespace') {
        if (arg.expression is StringLiteral) {
          return (arg.expression as StringLiteral).stringValue;
        }
      }
    }
    return null;
  }

  /// Extracts documentation text from a comment.
  String? _extractDocumentation(Comment? comment) {
    if (comment == null) return null;

    // Get the tokens from the comment
    final tokens = comment.tokens;
    if (tokens.isEmpty) return null;

    // Join all tokens and extract the documentation text
    final lines = tokens.map((token) => token.lexeme).toList();
    if (lines.isEmpty || !lines.first.startsWith('///')) return null;

    return lines
        .map((line) => line.replaceFirst(RegExp(r'^///\s?'), ''))
        .join('\n')
        .trim();
  }
}
