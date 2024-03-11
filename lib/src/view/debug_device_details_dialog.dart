import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/utils/device_info_manager.dart';

/// DebugDeviceDetailsDialog is a widget that displays the details of the device.
/// Allows for the inspection of device details such as the device name, model, and OS version.
class DebugDeviceDetailsDialog extends StatelessWidget {
  const DebugDeviceDetailsDialog({
    super.key,
    required this.onTap,
  });
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deviceInfoManager = DeviceInfoManager.instance;
    final screenSize = deviceInfoManager.getScreenSize(context);
    final screenDensity = deviceInfoManager.getScreenDensity(context);

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
                      'Device Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Screen Size'),
                        subtitle:
                            Text('${screenSize.width} x ${screenSize.height}'),
                      ),
                      ListTile(
                        title: const Text('Screen Density'),
                        subtitle: Text(screenDensity.toString()),
                      ),
                      ...state.value.deviceData.entries.map((entry) => ListTile(
                            title: Text(entry.key),
                            subtitle: Text('${entry.value}'),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
