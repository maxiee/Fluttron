# Annotations Reference

Fluttron provides two annotations for defining service contracts and models in `fluttron_shared`.

## Import

```dart
import 'package:fluttron_shared/fluttron_shared.dart';
```

## @FluttronServiceContract

Marks an abstract class as a Fluttron Host service contract.

### Syntax

```dart
@FluttronServiceContract(namespace: 'your_namespace')
abstract class YourService {
  // Method declarations
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `namespace` | `String` | Yes | The routing namespace for `namespace.method` calls |

### Namespace Rules

- Must be unique within the application's service registry
- Use snake_case convention (e.g., `weather_service`, `user_auth`)
- Avoid reserved namespaces: `file`, `dialog`, `clipboard`, `system`, `storage`
- Must be a valid Dart identifier

### Contract Class Requirements

1. Must be `abstract`
2. All methods must return `Future<T>`
3. Methods are public (no underscore prefix)

### Example

```dart
/// Service for managing user authentication.
@FluttronServiceContract(namespace: 'auth')
abstract class AuthService {
  /// Logs in a user and returns a session token.
  Future<Session> login(String email, String password);

  /// Logs out the current user.
  Future<void> logout();

  /// Checks if a user is currently logged in.
  Future<bool> isAuthenticated();

  /// Gets the current user's profile.
  Future<User?> getCurrentUser();
}
```

### Method Signatures

#### Positional Parameters

```dart
Future<Result> method(String param1, int param2);
```

Generated as required parameters.

#### Named Parameters with Defaults

```dart
Future<Result> method({int count = 10, bool flag = true});
```

Generated as optional parameters with default values.

#### Nullable Parameters

```dart
Future<Result> method(String required, {String? optional});
```

Optional parameters can be `null`.

#### Void Return

```dart
Future<void> doSomething();
```

Methods can return `void`.

### Unsupported Patterns

```dart
// ❌ Non-async methods
String syncMethod();  // Not supported

// ❌ Non-Future return types
int getValue();  // Must return Future<int>

// ❌ Sync callbacks
void registerCallback(Function cb);  // Not supported

// ❌ Generic methods
Future<T> genericMethod<T>();  // Not supported
```

---

## @FluttronModel

Marks a class as a serializable model for the Host-UI bridge.

### Syntax

```dart
@FluttronModel()
class YourModel {
  // Fields
}
```

### Model Class Requirements

1. All fields must be `final`
2. Must have a const constructor
3. All non-nullable fields must be `required` in constructor

### Example

```dart
/// User profile information.
@FluttronModel()
class UserProfile {
  final String id;
  final String name;
  final String email;
  final int age;
  final bool isActive;
  final DateTime createdAt;
  final String? bio;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.isActive,
    required this.createdAt,
    this.bio,
    required this.tags,
    required this.metadata,
  });
}
```

### Supported Field Types

#### Basic Types

| Type | Serialization | Deserialization |
|------|---------------|-----------------|
| `String` | Direct | `as String` |
| `int` | Direct | `as int` |
| `double` | Direct | `(as num).toDouble()` |
| `bool` | Direct | `as bool` |
| `num` | Direct | `as num` |
| `DateTime` | `toIso8601String()` | `DateTime.parse()` |

#### Nullable Types

All basic types support `?` suffix:
- `String?` → null or string
- `int?` → null or int
- `DateTime?` → null or ISO 8601 string

#### Collection Types

| Type | Serialization | Deserialization |
|------|---------------|-----------------|
| `List<T>` | `.map(toMap).toList()` | `.map(fromMap).toList()` |
| `Map<String, dynamic>` | Direct | `Map<String, dynamic>.from()` |

#### Nested Models

```dart
@FluttronModel()
class Order {
  final String id;
  final Customer customer;  // Another @FluttronModel
  final List<OrderItem> items;  // List of models

  const Order({
    required this.id,
    required this.customer,
    required this.items,
  });
}
```

### Generated Code

The code generator produces:

1. **`fromMap` factory**: Creates an instance from JSON
2. **`toMap` method**: Serializes to JSON

```dart
factory UserProfile.fromMap(Map<String, dynamic> map) {
  return UserProfile(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    age: map['age'] as int,
    isActive: map['isActive'] as bool,
    createdAt: DateTime.parse(map['createdAt'] as String),
    bio: map['bio'] == null ? null : map['bio'] as String,
    tags: (map['tags'] as List).map((e) => e as String).toList(),
    metadata: Map<String, dynamic>.from(map['metadata'] as Map),
  );
}

Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'email': email,
    'age': age,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'bio': bio,
    'tags': tags,
    'metadata': metadata,
  };
}
```

### Documentation

Model and field documentation is preserved in generated code:

```dart
/// User profile information.
@FluttronModel()
class UserProfile {
  /// Unique identifier for the user.
  final String id;

  /// Display name shown in the UI.
  final String name;
}
```

---

## Complete Example

```dart
import 'package:fluttron_shared/fluttron_shared.dart';

// Models

/// Weather information for a specific location.
@FluttronModel()
class WeatherInfo {
  /// City name.
  final String city;

  /// Temperature in Celsius.
  final double temperature;

  /// Weather condition description.
  final String condition;

  /// Timestamp of the reading.
  final DateTime timestamp;

  const WeatherInfo({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.timestamp,
  });
}

/// Daily weather forecast.
@FluttronModel()
class WeatherForecast {
  /// Forecast date.
  final DateTime date;

  /// High temperature in Celsius.
  final double high;

  /// Low temperature in Celsius.
  final double low;

  /// Weather condition.
  final String condition;

  const WeatherForecast({
    required this.date,
    required this.high,
    required this.low,
    required this.condition,
  });
}

// Service Contract

/// Weather service providing current conditions and forecasts.
@FluttronServiceContract(namespace: 'weather')
abstract class WeatherService {
  /// Gets current weather for the given city.
  Future<WeatherInfo> getCurrentWeather(String city);

  /// Gets the weather forecast.
  ///
  /// [city] — The city to get forecast for.
  /// [days] — Number of days (default: 5).
  Future<List<WeatherForecast>> getForecast(String city, {int days = 5});

  /// Checks if the weather API is available.
  Future<bool> isAvailable();
}
```

## Best Practices

### Namespace Naming

```dart
// ✅ Good
@FluttronServiceContract(namespace: 'user_auth')
@FluttronServiceContract(namespace: 'payment_gateway')

// ❌ Avoid
@FluttronServiceContract(namespace: 'AuthService')  // Not snake_case
@FluttronServiceContract(namespace: 'file')  // Reserved namespace
```

### Model Organization

```dart
// ✅ Good: Separate models file
// models/user_models.dart
@FluttronModel()
class User { ... }

// services/user_contract.dart
@FluttronServiceContract(namespace: 'user')
abstract class UserService { ... }
```

### Documentation

```dart
// ✅ Good: Document everything
/// Service for managing user notifications.
@FluttronServiceContract(namespace: 'notification')
abstract class NotificationService {
  /// Sends a notification to a specific user.
  ///
  /// [userId] — The target user's ID.
  /// [message] — The notification content.
  /// Returns the created notification ID.
  Future<String> send(String userId, String message);
}
```

## See Also

- [Code Generation Reference](./codegen.md) — CLI command documentation
- [Custom Services Tutorial](../getting-started/custom-services.md) — Step-by-step guide
- [Services API](./services.md) — Built-in service clients
