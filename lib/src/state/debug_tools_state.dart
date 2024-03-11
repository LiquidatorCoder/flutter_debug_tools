import 'package:flutter/material.dart';

class DebugToolsState {
  final Color? currentColor;
  final bool shouldShowToolsIndicator;
  final bool shouldShowToolsPanel;
  final bool shouldShowLogsScreen;
  final bool shouldShowColorPicker;
  final bool shouldShowPerformanceOverlay;

  const DebugToolsState({
    this.currentColor,
    this.shouldShowToolsIndicator = true,
    this.shouldShowToolsPanel = false,
    this.shouldShowLogsScreen = false,
    this.shouldShowColorPicker = false,
    this.shouldShowPerformanceOverlay = false,
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
    );
  }
}

final ValueNotifier<DebugToolsState> state =
    ValueNotifier<DebugToolsState>(const DebugToolsState());
