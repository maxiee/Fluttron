# Services API Reference

This document describes the services currently available in Fluttron.

## Available Services

| Service | Namespace | Status | Description |
|---------|-----------|--------|-------------|
| SystemService | `system` | ✅ Stable | Platform information |
| StorageService | `storage` | ✅ Stable | In-memory key-value storage |

## SystemService

### getPlatform()

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

**Dart Usage:**
```dart
final platform = await FluttronClient().getPlatform();
print('Running on: $platform');
```

---

## StorageService

### kvSet(key, value)

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

**Response:**
```json
{
  "id": "...",
  "ok": true,
  "result": { "ok": true },
  "error": null
}
```

**Dart Usage:**
```dart
await FluttronClient().kvSet('user.name', 'Alice');
```

---

### kvGet(key)

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

**Response (value exists):**
```json
{
  "id": "...",
  "ok": true,
  "result": { "value": "Alice" },
  "error": null
}
```

**Response (missing key):**
```json
{
  "id": "...",
  "ok": true,
  "result": { "value": null },
  "error": null
}
```

**Dart Usage:**
```dart
final name = await FluttronClient().kvGet('user.name');
print('User: $name');
```

---

## Error Handling

On failure, the response includes `ok: false` and an error string:

```json
{
  "id": "...",
  "ok": false,
  "result": null,
  "error": "METHOD_NOT_FOUND: system.foo not implemented"
}
```

Errors are strings formatted as `CODE:message` for expected failures, or
`internal_error:...` for unexpected exceptions.

## Next Steps

- [Architecture Overview](../architecture/overview.md) - System architecture
