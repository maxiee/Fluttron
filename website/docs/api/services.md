# Services API Reference

This document describes all available services in Fluttron and their APIs.

## Available Services

| Service | Namespace | Status | Description |
|---------|-----------|---------|-------------|
| SystemService | `system` | ✅ Stable | Platform information and system capabilities |
| StorageService | `storage` | ✅ Stable | Key-value storage (memory-based) |
| FileService | `file` | 🚧 Planned | File system access |
| DatabaseService | `database` | 🚧 Planned | SQLite database operations |

## SystemService

Provides platform information and system capabilities.

### Methods

#### getPlatform()

Returns the current platform name.

**Request:**
```json
{
  "id": "...",
  "method": "system.getPlatform",
  "params": {}
}
```

**Response:**
```json
{
  "id": "...",
  "ok": true,
  "result": {
    "platform": "macos"
  },
  "error": null
}
```

**Platform Values:**
- `macos` - macOS
- `linux` - Linux
- `windows` - Windows
- `android` - Android (planned)
- `ios` - iOS (planned)

**Dart Usage:**
```dart
final platform = await FluttronClient.getPlatform();
print('Running on: $platform');
```

---

## StorageService

Provides in-memory key-value storage.

### Methods

#### kvSet(key, value)

Store a key-value pair in memory.

**Request:**
```json
{
  "id": "...",
  "method": "storage.kvSet",
  "params": {
    "key": "user.name",
    "value": "Alice"
  }
}
```

**Parameters:**
- `key` (String): Storage key
- `value` (String): Storage value

**Response:**
```json
{
  "id": "...",
  "ok": true,
  "result": null,
  "error": null
}
```

**Dart Usage:**
```dart
await FluttronClient.kvSet('user.name', 'Alice');
await FluttronClient.kvSet('user.age', '30');
await FluttronClient.kvSet('session.token', 'abc123');
```

---

#### kvGet(key)

Retrieve a value by key from memory storage.

**Request:**
```json
{
  "id": "...",
  "method": "storage.kvGet",
  "params": {
    "key": "user.name"
  }
}
```

**Parameters:**
- `key` (String): Storage key to retrieve

**Response:**
```json
{
  "id": "...",
  "ok": true,
  "result": "Alice",
  "error": null
}
```

**Dart Usage:**
```dart
final name = await FluttronClient.kvGet('user.name');
print('User: $name');

final age = await FluttronClient.kvGet('user.age');
print('Age: $age');
```

**Null Value:**
```dart
final unknown = await FluttronClient.kvGet('unknown.key');
if (unknown == null) {
  print('Key does not exist');
}
```

---

## Usage Example

Complete example using multiple services:

```dart
class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _platform = 'Loading...';
  String _storedValue = 'Not set';
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlatform();
  }

  Future<void> _loadPlatform() async {
    try {
      final platform = await FluttronClient.getPlatform();
      setState(() {
        _platform = platform;
      });
    } catch (e) {
      setState(() {
        _platform = 'Error: $e';
      });
    }
  }

  Future<void> _storeValue() async {
    try {
      await FluttronClient.kvSet(
        _keyController.text,
        _valueController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadValue() async {
    try {
      final value = await FluttronClient.kvGet(_keyController.text);
      setState(() {
        _storedValue = value ?? 'Not found';
      });
    } catch (e) {
      setState(() {
        _storedValue = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fluttron Demo')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Platform: $_platform'),
            SizedBox(height: 20),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: 'Key'),
            ),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(labelText: 'Value'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _storeValue,
              child: Text('Store'),
            ),
            ElevatedButton(
              onPressed: _loadValue,
              child: Text('Load'),
            ),
            Text('Value: $_storedValue'),
          ],
        ),
      ),
    );
  }
}
```

## Error Handling

All service methods can throw exceptions:

```dart
try {
  final platform = await FluttronClient.getPlatform();
  print(platform);
} on FluttronError catch (e) {
  print('Fluttron error: ${e.code} - ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Common Error Codes

| Code | Description |
|------|-------------|
| `UNKNOWN_METHOD` | Method not found |
| `INVALID_PARAMS` | Invalid parameters |
| `PERMISSION_DENIED` | Insufficient permissions |
| `INTERNAL_ERROR` | Internal server error |

## Next Steps

- [Architecture Overview](../architecture/overview.md) - Learn about Fluttron architecture
