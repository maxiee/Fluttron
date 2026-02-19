# fluttron_shared

Shared data models, protocols, and annotations for Fluttron host ↔ UI communication.

Used by both `fluttron_host` (native side) and `fluttron_ui` (Flutter Web side).

## Bridge Protocol

All Host ↔ UI communication uses these three types:

```dart
import 'package:fluttron_shared/fluttron_shared.dart';

// Outgoing request from UI to Host
final request = FluttronRequest(
  id: 'req-1',
  method: 'file.readFile',
  params: {'path': '/tmp/hello.txt'},
);

// Response from Host to UI
final response = FluttronResponse(ok: true, result: 'file contents');

// Typed error
final error = FluttronError('FILE_NOT_FOUND', 'Path does not exist');
```

## Service Contract Annotations

Use annotations to define typed service contracts for code generation:

```dart
import 'package:fluttron_shared/fluttron_shared.dart';

@FluttronServiceContract(namespace: 'weather')
abstract class WeatherServiceContract {
  Future<WeatherInfo> getCurrentWeather({required String city});
  Future<List<WeatherInfo>> getForecast({required String city, int days = 5});
}

@FluttronModel()
class WeatherInfo {
  final String city;
  final double temperature;
  final String condition;

  WeatherInfo({required this.city, required this.temperature, required this.condition});
}
```

Then generate Host, Client, and Model code with:

```bash
fluttron generate services --contract lib/src/weather_contract.dart ...
```

## Models

| Type | Description |
|------|-------------|
| `FluttronRequest` | RPC request: `id`, `method`, `params` |
| `FluttronResponse` | RPC response: `ok`, `result?`, `error?` |
| `FluttronError` | Typed error: `code`, `message` |
| `FluttronManifest` | Web package manifest (`fluttron_package.json`) |
| `FileEntry` | Directory listing entry |
| `FileStat` | File metadata (size, modified, isDirectory) |

## Annotations

| Annotation | Purpose |
|------------|---------|
| `@FluttronServiceContract(namespace:)` | Marks a Dart abstract class as a service contract for code generation |
| `@FluttronModel()` | Marks a class for `fromMap`/`toMap` serialization generation |

## Documentation

Full documentation: <https://maxiee.github.io/Fluttron/>

- [Code Generation Guide](https://maxiee.github.io/Fluttron/docs/api/codegen)
- [Annotations Reference](https://maxiee.github.io/Fluttron/docs/api/annotations)
- [Architecture Overview](https://maxiee.github.io/Fluttron/docs/architecture/overview)
