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
  final String? currentScreen;
  final bool shouldShowScreenName;
  final bool shouldShowRenderBoxDetails;

  const DebugToolsState({
    this.currentColor,
    this.shouldShowToolsIndicator = true,
    this.shouldShowToolsPanel = false,
    this.shouldShowLogsScreen = false,
    this.shouldShowColorPicker = false,
    this.shouldShowPerformanceOverlay = false,
    this.deviceData = const {},
    this.shouldShowDeviceDetails = false,
    this.currentScreen,
    this.shouldShowScreenName = false,
    this.shouldShowRenderBoxDetails = false,
  });

  DebugToolsState copyWith({
    Color? currentColor,
    bool? shouldShowToolsIndicator,
    bool? shouldShowToolsPanel,
    bool? shouldShowLogsScreen,
    bool? shouldShowColorPicker,
    bool? shouldShowPerformanceOverlay,
    Map<String, dynamic>? deviceData,
    bool? shouldShowDeviceDetails,
    String? currentScreen,
    bool? shouldShowScreenName,
    bool? shouldShowRenderBoxDetails,
  }) {
    return DebugToolsState(
      currentColor: currentColor ?? this.currentColor,
      shouldShowToolsIndicator: shouldShowToolsIndicator ?? this.shouldShowToolsIndicator,
      shouldShowToolsPanel: shouldShowToolsPanel ?? this.shouldShowToolsPanel,
      shouldShowLogsScreen: shouldShowLogsScreen ?? this.shouldShowLogsScreen,
      shouldShowColorPicker: shouldShowColorPicker ?? this.shouldShowColorPicker,
      shouldShowPerformanceOverlay: shouldShowPerformanceOverlay ?? this.shouldShowPerformanceOverlay,
      deviceData: deviceData ?? this.deviceData,
      shouldShowDeviceDetails: shouldShowDeviceDetails ?? this.shouldShowDeviceDetails,
      currentScreen: currentScreen ?? this.currentScreen,
      shouldShowScreenName: shouldShowScreenName ?? this.shouldShowScreenName,
      shouldShowRenderBoxDetails: shouldShowRenderBoxDetails ?? this.shouldShowRenderBoxDetails,
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
      currentScreen: currentScreen,
    );
  }
}

final ValueNotifier<DebugToolsState> state = ValueNotifier<DebugToolsState>(const DebugToolsState());

class RenderBoxInfo {
  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;
  final Offset overlayOffset;

  RenderBoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
  });

  Rect get targetRect => getRectFromRenderBox(targetRenderBox)!;
  Rect get targetRectShifted => targetRect.shift(-overlayOffset);
  Rect? get containerRect => containerRenderBox != null ? getRectFromRenderBox(containerRenderBox!) : null;

  Rect? getRectFromRenderBox(RenderBox renderBox) {
    return renderBox.attached ? (renderBox.localToGlobal(Offset.zero)) & renderBox.size : null;
  }

  double? get paddingLeft => paddingRectLeft?.width;
  double? get paddingRight => paddingRectRight?.width;
  double? get paddingTop => paddingRectTop?.height;
  double? get paddingBottom => paddingRectBottom?.height;
  double? get paddingHorizontal => (paddingLeft ?? 0) + (paddingRight ?? 0);
  double? get paddingVertical => (paddingTop ?? 0) + (paddingBottom ?? 0);

  Rect? get paddingRectLeft => containerRect != null
      ? Rect.fromLTRB(containerRect!.left, containerRect!.top, targetRect.left, containerRect!.bottom)
      : null;

  Rect? get paddingRectTop => containerRect != null
      ? Rect.fromLTRB(targetRect.left, containerRect!.top, targetRect.right, targetRect.top)
      : null;

  Rect? get paddingRectRight => containerRect != null
      ? Rect.fromLTRB(targetRect.right, containerRect!.top, containerRect!.right, containerRect!.bottom)
      : null;

  Rect? get paddingRectBottom => containerRect != null
      ? Rect.fromLTRB(targetRect.left, targetRect.bottom, targetRect.right, containerRect!.bottom)
      : null;
}
