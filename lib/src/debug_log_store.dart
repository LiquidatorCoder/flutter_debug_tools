import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum DebugLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

class DebugLogEntry {
  const DebugLogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  final String message;
  final DebugLogLevel level;
  final DateTime timestamp;
}

class DebugLogStore {
  DebugLogStore._();

  static final DebugLogStore instance = DebugLogStore._();

  static const int _maxLogs = 1000;

  final ValueNotifier<List<DebugLogEntry>> logs = ValueNotifier<List<DebugLogEntry>>(<DebugLogEntry>[]);

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

  void addError(Object error, StackTrace stackTrace) {
    add(error.toString(), level: DebugLogLevel.error);
    final stackTraceMessage = stackTrace.toString().trim();
    if (stackTraceMessage.isNotEmpty) {
      add(stackTraceMessage, level: DebugLogLevel.error);
    }
  }

  void clear() {
    logs.value = <DebugLogEntry>[];
  }

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

class DebugLogCapture {
  DebugLogCapture._();

  static bool _isInstalled = false;
  static FlutterExceptionHandler? _previousFlutterErrorHandler;
  static ErrorCallback? _previousPlatformErrorHandler;

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

      _previousFlutterErrorHandler?.call(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      DebugLogStore.instance.addError(error, stackTrace);
      return _previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
    };
  }

  static Future<void> runApp(FutureOr<void> Function() appRunner) async {
    install();

    await runZonedGuarded(
      () async {
        await appRunner();
      },
      (Object error, StackTrace stackTrace) {
        DebugLogStore.instance.addError(error, stackTrace);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          DebugLogStore.instance.add(line);
          parent.print(zone, line);
        },
      ),
    );
  }
}
