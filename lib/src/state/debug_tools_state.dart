import 'package:flutter/material.dart';

class DebugToolsState {
  final Color? currentColor;
  final bool shouldShowToolsIndicator;
  final bool shouldShowToolsPanel;
  final bool shouldShowLogsScreen;
  final bool shouldShowColorPicker;
  final bool shouldShowPerformanceOverlay;
  final Map<String, dynamic> deviceData;
  final bool shouldShowDeviceDetails;

  const DebugToolsState({
    this.currentColor,
    this.shouldShowToolsIndicator = true,
    this.shouldShowToolsPanel = false,
    this.shouldShowLogsScreen = false,
    this.shouldShowColorPicker = false,
    this.shouldShowPerformanceOverlay = false,
    this.deviceData = const {},
    this.shouldShowDeviceDetails = false,
  });

  DebugToolsState copyWith({
    Color? currentColor,
    bool? shouldShowToolsIndicator,
    bool? shouldShowToolsPanel,
    bool? shouldShowLogsScreen,
    bool? shouldShowColorPicker,
    bool? isDebugPaintSizeEnabled,
    bool? isDebugPaintLayerBordersEnabled,
    bool? isDebugRepaintTextRainbowEnabled,
    bool? shouldShowPerformanceOverlay,
    Map<String, dynamic>? deviceData,
    bool? shouldShowDeviceDetails,
  }) {
    return DebugToolsState(
      currentColor: currentColor ?? this.currentColor,
      shouldShowToolsIndicator:
          shouldShowToolsIndicator ?? this.shouldShowToolsIndicator,
      shouldShowToolsPanel: shouldShowToolsPanel ?? this.shouldShowToolsPanel,
      shouldShowLogsScreen: shouldShowLogsScreen ?? this.shouldShowLogsScreen,
      shouldShowColorPicker:
          shouldShowColorPicker ?? this.shouldShowColorPicker,
      shouldShowPerformanceOverlay:
          shouldShowPerformanceOverlay ?? this.shouldShowPerformanceOverlay,
      deviceData: deviceData ?? this.deviceData,
      shouldShowDeviceDetails:
          shouldShowDeviceDetails ?? this.shouldShowDeviceDetails,
    );
  }

  DebugToolsState clearColor() {
    return DebugToolsState(
      currentColor: null,
      shouldShowToolsIndicator: shouldShowToolsIndicator,
      shouldShowToolsPanel: shouldShowToolsPanel,
      shouldShowLogsScreen: shouldShowLogsScreen,
      shouldShowColorPicker: shouldShowColorPicker,
      shouldShowPerformanceOverlay: shouldShowPerformanceOverlay,
      deviceData: deviceData,
      shouldShowDeviceDetails: shouldShowDeviceDetails,
    );
  }
}

final ValueNotifier<DebugToolsState> state =
    ValueNotifier<DebugToolsState>(const DebugToolsState());
