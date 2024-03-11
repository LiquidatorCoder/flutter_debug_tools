import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

/// A [LoggyPrinter] that prints logs to the console and stores them in a list so
/// they can be accessed programmatically.
class DebugLoggyPrinter extends LoggyPrinter {
  final List<String> _logs = [];

  /// The stored logs.
  List<String> get logs => _logs;

  @override
  void onLog(LogRecord record) {
    final logMessage = '${record.level.name}: ${record.message}';
    debugPrint(logMessage);
    _logs.add(logMessage);
  }

  /// Clears the stored logs.
  void clearLogs() {
    _logs.clear();
  }
}
