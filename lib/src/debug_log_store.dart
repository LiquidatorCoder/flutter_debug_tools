import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Severity levels used by [DebugLogEntry] and [DebugLogStore].
enum DebugLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// A single captured log row with message, severity, and timestamp.
class DebugLogEntry {
  /// Creates a log entry snapshot.
  const DebugLogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  /// Raw text payload captured from print/error handlers.
  final String message;

  /// Severity inferred from message content or provided explicitly.
  final DebugLogLevel level;

  /// Time when this entry was added to the store.
  final DateTime timestamp;
}

/// In-memory log buffer used by FlutterLens log viewer.
class DebugLogStore {
  DebugLogStore._();

  /// Singleton instance shared by FlutterLens internals and app code.
  static final DebugLogStore instance = DebugLogStore._();

  static const int _maxLogs = 1000;

  /// Reactive list of currently captured log entries.
  final ValueNotifier<List<DebugLogEntry>> logs = ValueNotifier<List<DebugLogEntry>>(<DebugLogEntry>[]);

  /// Adds a log message to the store.
  ///
  /// If [level] is omitted, a best-effort level is inferred from [message].
  void add(
    String message, {
    DebugLogLevel? level,
  }) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      return;
    }

    final next = List<DebugLogEntry>.from(logs.value)
      ..add(
        DebugLogEntry(
          message: normalized,
          level: level ?? _resolveLevel(normalized),
          timestamp: DateTime.now(),
        ),
      );

    if (next.length > _maxLogs) {
      next.removeRange(0, next.length - _maxLogs);
    }

    logs.value = next;
  }

  /// Adds an error and stack trace as `error`-level log entries.
  void addError(Object error, StackTrace stackTrace) {
    add(error.toString(), level: DebugLogLevel.error);
    final stackTraceMessage = stackTrace.toString().trim();
    if (stackTraceMessage.isNotEmpty) {
      add(stackTraceMessage, level: DebugLogLevel.error);
    }
  }

  /// Clears all currently captured entries.
  void clear() {
    logs.value = <DebugLogEntry>[];
  }

  /// Read-only snapshot view of [logs].
  UnmodifiableListView<DebugLogEntry> get entries => UnmodifiableListView<DebugLogEntry>(logs.value);

  DebugLogLevel _resolveLevel(String message) {
    final lower = message.toLowerCase();

    if (lower.startsWith('e/') ||
        lower.contains(' error') ||
        lower.startsWith('error') ||
        lower.contains('exception') ||
        lower.contains('fatal')) {
      return DebugLogLevel.error;
    }

    if (lower.startsWith('w/') || lower.startsWith('warn') || lower.contains(' warning')) {
      return DebugLogLevel.warning;
    }

    if (lower.startsWith('d/') || lower.startsWith('debug') || lower.contains(' debug')) {
      return DebugLogLevel.debug;
    }

    if (lower.startsWith('v/') || lower.startsWith('verbose') || lower.startsWith('trace')) {
      return DebugLogLevel.verbose;
    }

    return DebugLogLevel.info;
  }
}

/// Hooks framework and zone-level logging into [DebugLogStore].
class DebugLogCapture {
  DebugLogCapture._();

  static bool _isInstalled = false;
  static FlutterExceptionHandler? _previousFlutterErrorHandler;
  static ErrorCallback? _previousPlatformErrorHandler;

  /// Installs Flutter/framework error hooks once for the current process.
  static void install() {
    if (_isInstalled) {
      return;
    }

    _isInstalled = true;
    _previousFlutterErrorHandler = FlutterError.onError;
    _previousPlatformErrorHandler = PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      DebugLogStore.instance.add(details.exceptionAsString(), level: DebugLogLevel.error);

      final diagnostics = details.stack?.toString().trim();
      if (diagnostics != null && diagnostics.isNotEmpty) {
        DebugLogStore.instance.add(diagnostics, level: DebugLogLevel.error);
      }

      if (_previousFlutterErrorHandler != null) {
        _previousFlutterErrorHandler!.call(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      DebugLogStore.instance.addError(error, stackTrace);
      return _previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
    };
  }

  /// Runs app bootstrap in a guarded zone that captures `print` and uncaught errors.
  ///
  /// Typically used in `main()` to enable in-app log collection before `runApp`.
  static Future<void> runApp(FutureOr<void> Function() appRunner) async {
    install();

    await runZonedGuarded(
      () async {
        await appRunner();
      },
      (Object error, StackTrace stackTrace) {
        DebugLogStore.instance.addError(error, stackTrace);
        _printErrorToConsole(error, stackTrace);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          DebugLogStore.instance.add(line);
          parent.print(zone, line);
        },
      ),
    );
  }

  static void _printErrorToConsole(Object error, StackTrace stackTrace) {
    FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
      ),
      forceReport: true,
    );
  }
}
