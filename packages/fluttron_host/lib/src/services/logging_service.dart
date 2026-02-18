import 'package:fluttron_host/src/services/service.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

class _LogEntry {
  _LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
  });

  final String timestamp;
  final String level;
  final String message;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'timestamp': timestamp,
      'level': level,
      'message': message,
    };
    if (data != null) map['data'] = data;
    return map;
  }
}

/// Service for structured logging with in-memory ring buffer storage.
///
/// Namespace: `logging`
///
/// Methods:
/// - `log(level: String, message: String, data: Map?)` — Log a message
/// - `getLogs(level: String?, limit: int?)` — Retrieve recent logs
/// - `clear()` — Clear the log buffer
class LoggingService extends FluttronService {
  /// Creates a [LoggingService] with an optional [bufferSize].
  ///
  /// Defaults to 1000 entries. When the buffer is full, the oldest entry is
  /// dropped to make room for the new one.
  LoggingService({int bufferSize = 1000}) : _bufferSize = bufferSize;

  final int _bufferSize;
  final List<_LogEntry> _buffer = [];

  static const _validLevels = {'debug', 'info', 'warn', 'error'};

  @override
  String get namespace => 'logging';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'log':
        final level = params['level'];
        final message = params['message'];
        if (level is! String) {
          throw FluttronError(
            'BAD_PARAMS',
            'logging.log: level must be a String',
          );
        }
        if (message is! String) {
          throw FluttronError(
            'BAD_PARAMS',
            'logging.log: message must be a String',
          );
        }
        if (!_validLevels.contains(level)) {
          throw FluttronError(
            'BAD_PARAMS',
            'logging.log: level must be one of: debug, info, warn, error',
          );
        }
        final rawData = params['data'];
        Map<String, dynamic>? data;
        if (rawData != null) {
          if (rawData is! Map) {
            throw FluttronError(
              'BAD_PARAMS',
              'logging.log: data must be a Map if provided',
            );
          }
          data = Map<String, dynamic>.from(rawData);
        }
        _appendLog(level, message, data);
        return null;

      case 'getLogs':
        final levelFilter = params['level'];
        final limitParam = params['limit'];
        if (levelFilter != null && levelFilter is! String) {
          throw FluttronError(
            'BAD_PARAMS',
            'logging.getLogs: level must be a String if provided',
          );
        }
        if (limitParam != null && limitParam is! int) {
          throw FluttronError(
            'BAD_PARAMS',
            'logging.getLogs: limit must be an int if provided',
          );
        }
        return _getLogs(
          level: levelFilter as String?,
          limit: limitParam as int?,
        );

      case 'clear':
        _buffer.clear();
        return null;

      default:
        throw FluttronError(
          'METHOD_NOT_FOUND',
          'logging.$method not implemented',
        );
    }
  }

  void _appendLog(String level, String message, Map<String, dynamic>? data) {
    final entry = _LogEntry(
      timestamp: DateTime.now().toIso8601String(),
      level: level,
      message: message,
      data: data,
    );
    if (_buffer.length >= _bufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(entry);

    final dataStr = data != null ? ' | $data' : '';
    // ignore: avoid_print
    print(
      '[Fluttron] [${entry.timestamp}] [${level.toUpperCase()}] $message$dataStr',
    );
  }

  List<Map<String, dynamic>> _getLogs({String? level, int? limit}) {
    var entries = List<_LogEntry>.from(_buffer);
    if (level != null) {
      entries = entries.where((e) => e.level == level).toList();
    }
    if (limit != null && limit > 0 && limit < entries.length) {
      entries = entries.sublist(entries.length - limit);
    }
    return entries.map((e) => e.toMap()).toList();
  }
}
