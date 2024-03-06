import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';

class DebugLoggyPrinter extends LoggyPrinter {
  final List<String> _logs = [];

  List<String> get logs => _logs;

  @override
  void onLog(LogRecord record) {
    final logMessage = '${record.level.name}: ${record.message}';
    debugPrint(logMessage);
    _logs.add(logMessage);
  }

  void clearLogs() {
    _logs.clear();
  }
}
