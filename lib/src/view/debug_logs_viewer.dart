import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/src/debug_loggy_printer.dart';
import 'package:loggy/loggy.dart';

/// DebugLogsViewer is a widget that displays a list of logs.
/// Allows for the inspection of log messages generated by the application.
class DebugLogsViewer extends StatelessWidget {
  const DebugLogsViewer({
    super.key,
    required this.onTap,
  });
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final logs = Loggy.currentPrinter as DebugLoggyPrinter?;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Debug Logs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Transform.rotate(
                    angle: pi / 4,
                    child: IconButton(
                      onPressed: onTap,
                      icon: const Text(
                        "+",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: logs?.logs.where((e) => e.isNotEmpty).length,
                  itemBuilder: (context, index) {
                    if (logs?.logs.where((e) => e.isNotEmpty).toList()[index] ==
                        "") {
                      return const SizedBox.shrink();
                    }

                    return ListTile(
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        logs?.logs.where((e) => e.isNotEmpty).toList()[index] ??
                            "",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
