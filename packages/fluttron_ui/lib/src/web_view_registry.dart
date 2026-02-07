import 'package:flutter/foundation.dart';

class FluttronWebViewRegistration {
  const FluttronWebViewRegistration({
    required this.type,
    required this.jsFactoryName,
  });

  final String type;
  final String jsFactoryName;
}

abstract final class FluttronWebViewRegistry {
  static final Map<String, FluttronWebViewRegistration> _registrationsByType =
      <String, FluttronWebViewRegistration>{};

  static void register(FluttronWebViewRegistration registration) {
    final FluttronWebViewRegistration normalizedRegistration =
        _normalizeRegistration(registration);
    final FluttronWebViewRegistration? existingRegistration =
        _registrationsByType[normalizedRegistration.type];

    if (existingRegistration == null) {
      _registrationsByType[normalizedRegistration.type] =
          normalizedRegistration;
      return;
    }

    if (existingRegistration.jsFactoryName ==
        normalizedRegistration.jsFactoryName) {
      return;
    }

    throw StateError(
      'Conflicting FluttronWebViewRegistration for type '
      '"${normalizedRegistration.type}". Existing '
      'jsFactoryName="${existingRegistration.jsFactoryName}", incoming '
      'jsFactoryName="${normalizedRegistration.jsFactoryName}".',
    );
  }

  static void registerAll(Iterable<FluttronWebViewRegistration> registrations) {
    for (final FluttronWebViewRegistration registration in registrations) {
      register(registration);
    }
  }

  static bool isRegistered(String type) {
    final String normalizedType = _normalizeType(type, parameterName: 'type');
    return _registrationsByType.containsKey(normalizedType);
  }

  static FluttronWebViewRegistration lookup(String type) {
    final String normalizedType = _normalizeType(type, parameterName: 'type');
    final FluttronWebViewRegistration? registration =
        _registrationsByType[normalizedType];
    if (registration != null) {
      return registration;
    }

    throw StateError(
      'Fluttron web view type "$normalizedType" is not registered. '
      'Register it with FluttronWebViewRegistry.register(...) before '
      'rendering FluttronHtmlView.',
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    _registrationsByType.clear();
  }

  static FluttronWebViewRegistration _normalizeRegistration(
    FluttronWebViewRegistration registration,
  ) {
    final String normalizedType = _normalizeType(
      registration.type,
      parameterName: 'type',
    );
    final String normalizedFactoryName = _normalizeJsFactoryName(
      registration.jsFactoryName,
      parameterName: 'jsFactoryName',
    );

    return FluttronWebViewRegistration(
      type: normalizedType,
      jsFactoryName: normalizedFactoryName,
    );
  }

  static String _normalizeType(String value, {required String parameterName}) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        '$parameterName must not be empty.',
      );
    }
    return normalized;
  }

  static String _normalizeJsFactoryName(
    String value, {
    required String parameterName,
  }) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        '$parameterName must not be empty.',
      );
    }
    return normalized;
  }
}
