import 'package:flutter/material.dart';

enum AnimationCurvePreset {
  system('system', 'System'),
  linear('linear', 'Linear'),
  easeIn('easeIn', 'Ease In'),
  easeOut('easeOut', 'Ease Out'),
  easeInOut('easeInOut', 'Ease In Out'),
  easeInCubic('easeInCubic', 'Ease In Cubic'),
  easeOutCubic('easeOutCubic', 'Ease Out Cubic'),
  easeInOutCubic('easeInOutCubic', 'Ease In Out Cubic'),
  fastOutSlowIn('fastOutSlowIn', 'Fast Out Slow In'),
  decelerate('decelerate', 'Decelerate'),
  bounceIn('bounceIn', 'Bounce In'),
  bounceOut('bounceOut', 'Bounce Out'),
  bounceInOut('bounceInOut', 'Bounce In Out'),
  elasticOut('elasticOut', 'Elastic Out'),
  easeOutBack('easeOutBack', 'Ease Out Back');

  const AnimationCurvePreset(this.id, this.label);

  final String id;
  final String label;

  static AnimationCurvePreset fromId(String id) {
    for (final value in AnimationCurvePreset.values) {
      if (value.id == id) {
        return value;
      }
    }
    return AnimationCurvePreset.system;
  }
}

class DebugToolsState {
  static const double defaultAnimationSpeedFactor = 1.0;
  static const double defaultAnimationHighlightSensitivity = 18.0;
  static const int defaultAnimationHighlightIntervalMs = 120;
  static const int defaultAnimationHighlightDecayMs = 450;
  static const double defaultAnimationHighlightOpacity = 0.45;

  final Color? currentColor;
  final bool shouldShowToolsIndicator;
  final bool shouldShowToolsPanel;
  final bool shouldShowLogsScreen;
  final bool shouldShowNetworkScreen;
  final bool shouldShowColorPicker;
  final bool shouldShowPerformanceOverlay;
  final Map<String, dynamic> deviceData;
  final bool shouldShowDeviceDetails;
  final String? currentScreen;
  final bool shouldShowScreenName;
  final bool shouldShowRenderBoxDetails;
  final bool shouldShowAnimationToolbox;
  final double animationSpeedFactor;
  final AnimationCurvePreset animationCurvePreset;
  final bool shouldPauseAnimations;
  final bool shouldDisableAnimations;
  final bool shouldShowFrameTimingHud;
  final bool shouldShowAnimationHighlights;
  final bool shouldUseAnimationHighlightCompatibility;
  final double animationHighlightSensitivity;
  final int animationHighlightIntervalMs;
  final int animationHighlightDecayMs;
  final double animationHighlightOpacity;
  final String? animationHighlightUnavailableReason;

  const DebugToolsState({
    this.currentColor,
    this.shouldShowToolsIndicator = true,
    this.shouldShowToolsPanel = false,
    this.shouldShowLogsScreen = false,
    this.shouldShowNetworkScreen = false,
    this.shouldShowColorPicker = false,
    this.shouldShowPerformanceOverlay = false,
    this.deviceData = const {},
    this.shouldShowDeviceDetails = false,
    this.currentScreen,
    this.shouldShowScreenName = false,
    this.shouldShowRenderBoxDetails = false,
    this.shouldShowAnimationToolbox = false,
    this.animationSpeedFactor = defaultAnimationSpeedFactor,
    this.animationCurvePreset = AnimationCurvePreset.system,
    this.shouldPauseAnimations = false,
    this.shouldDisableAnimations = false,
    this.shouldShowFrameTimingHud = false,
    this.shouldShowAnimationHighlights = false,
    this.shouldUseAnimationHighlightCompatibility = false,
    this.animationHighlightSensitivity = defaultAnimationHighlightSensitivity,
    this.animationHighlightIntervalMs = defaultAnimationHighlightIntervalMs,
    this.animationHighlightDecayMs = defaultAnimationHighlightDecayMs,
    this.animationHighlightOpacity = defaultAnimationHighlightOpacity,
    this.animationHighlightUnavailableReason,
  });

  DebugToolsState copyWith({
    Color? currentColor,
    bool? shouldShowToolsIndicator,
    bool? shouldShowToolsPanel,
    bool? shouldShowLogsScreen,
    bool? shouldShowNetworkScreen,
    bool? shouldShowColorPicker,
    bool? shouldShowPerformanceOverlay,
    Map<String, dynamic>? deviceData,
    bool? shouldShowDeviceDetails,
    String? currentScreen,
    bool? shouldShowScreenName,
    bool? shouldShowRenderBoxDetails,
    bool? shouldShowAnimationToolbox,
    double? animationSpeedFactor,
    AnimationCurvePreset? animationCurvePreset,
    bool? shouldPauseAnimations,
    bool? shouldDisableAnimations,
    bool? shouldShowFrameTimingHud,
    bool? shouldShowAnimationHighlights,
    bool? shouldUseAnimationHighlightCompatibility,
    double? animationHighlightSensitivity,
    int? animationHighlightIntervalMs,
    int? animationHighlightDecayMs,
    double? animationHighlightOpacity,
    Object? animationHighlightUnavailableReason = _sentinel,
  }) {
    return DebugToolsState(
      currentColor: currentColor ?? this.currentColor,
      shouldShowToolsIndicator: shouldShowToolsIndicator ?? this.shouldShowToolsIndicator,
      shouldShowToolsPanel: shouldShowToolsPanel ?? this.shouldShowToolsPanel,
      shouldShowLogsScreen: shouldShowLogsScreen ?? this.shouldShowLogsScreen,
      shouldShowNetworkScreen: shouldShowNetworkScreen ?? this.shouldShowNetworkScreen,
      shouldShowColorPicker: shouldShowColorPicker ?? this.shouldShowColorPicker,
      shouldShowPerformanceOverlay: shouldShowPerformanceOverlay ?? this.shouldShowPerformanceOverlay,
      deviceData: deviceData ?? this.deviceData,
      shouldShowDeviceDetails: shouldShowDeviceDetails ?? this.shouldShowDeviceDetails,
      currentScreen: currentScreen ?? this.currentScreen,
      shouldShowScreenName: shouldShowScreenName ?? this.shouldShowScreenName,
      shouldShowRenderBoxDetails: shouldShowRenderBoxDetails ?? this.shouldShowRenderBoxDetails,
      shouldShowAnimationToolbox: shouldShowAnimationToolbox ?? this.shouldShowAnimationToolbox,
      animationSpeedFactor: animationSpeedFactor ?? this.animationSpeedFactor,
      animationCurvePreset: animationCurvePreset ?? this.animationCurvePreset,
      shouldPauseAnimations: shouldPauseAnimations ?? this.shouldPauseAnimations,
      shouldDisableAnimations: shouldDisableAnimations ?? this.shouldDisableAnimations,
      shouldShowFrameTimingHud: shouldShowFrameTimingHud ?? this.shouldShowFrameTimingHud,
      shouldShowAnimationHighlights: shouldShowAnimationHighlights ?? this.shouldShowAnimationHighlights,
      shouldUseAnimationHighlightCompatibility:
          shouldUseAnimationHighlightCompatibility ?? this.shouldUseAnimationHighlightCompatibility,
      animationHighlightSensitivity: animationHighlightSensitivity ?? this.animationHighlightSensitivity,
      animationHighlightIntervalMs: animationHighlightIntervalMs ?? this.animationHighlightIntervalMs,
      animationHighlightDecayMs: animationHighlightDecayMs ?? this.animationHighlightDecayMs,
      animationHighlightOpacity: animationHighlightOpacity ?? this.animationHighlightOpacity,
      animationHighlightUnavailableReason: identical(animationHighlightUnavailableReason, _sentinel)
          ? this.animationHighlightUnavailableReason
          : animationHighlightUnavailableReason as String?,
    );
  }

  DebugToolsState clearColor() {
    return DebugToolsState(
      currentColor: null,
      shouldShowToolsIndicator: shouldShowToolsIndicator,
      shouldShowToolsPanel: shouldShowToolsPanel,
      shouldShowLogsScreen: shouldShowLogsScreen,
      shouldShowNetworkScreen: shouldShowNetworkScreen,
      shouldShowColorPicker: shouldShowColorPicker,
      shouldShowPerformanceOverlay: shouldShowPerformanceOverlay,
      deviceData: deviceData,
      shouldShowDeviceDetails: shouldShowDeviceDetails,
      currentScreen: currentScreen,
      shouldShowScreenName: shouldShowScreenName,
      shouldShowRenderBoxDetails: shouldShowRenderBoxDetails,
      shouldShowAnimationToolbox: shouldShowAnimationToolbox,
      animationSpeedFactor: animationSpeedFactor,
      animationCurvePreset: animationCurvePreset,
      shouldPauseAnimations: shouldPauseAnimations,
      shouldDisableAnimations: shouldDisableAnimations,
      shouldShowFrameTimingHud: shouldShowFrameTimingHud,
      shouldShowAnimationHighlights: shouldShowAnimationHighlights,
      shouldUseAnimationHighlightCompatibility: shouldUseAnimationHighlightCompatibility,
      animationHighlightSensitivity: animationHighlightSensitivity,
      animationHighlightIntervalMs: animationHighlightIntervalMs,
      animationHighlightDecayMs: animationHighlightDecayMs,
      animationHighlightOpacity: animationHighlightOpacity,
      animationHighlightUnavailableReason: animationHighlightUnavailableReason,
    );
  }

  DebugToolsState resetAnimationToolboxSettings() {
    return copyWith(
      animationSpeedFactor: defaultAnimationSpeedFactor,
      animationCurvePreset: AnimationCurvePreset.system,
      shouldPauseAnimations: false,
      shouldDisableAnimations: false,
      shouldShowFrameTimingHud: false,
      shouldShowAnimationHighlights: false,
      shouldUseAnimationHighlightCompatibility: false,
      animationHighlightSensitivity: defaultAnimationHighlightSensitivity,
      animationHighlightIntervalMs: defaultAnimationHighlightIntervalMs,
      animationHighlightDecayMs: defaultAnimationHighlightDecayMs,
      animationHighlightOpacity: defaultAnimationHighlightOpacity,
      animationHighlightUnavailableReason: null,
    );
  }
}

const Object _sentinel = Object();

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

  Rect get paddingRect => Rect.fromLTRB(paddingLeft ?? 0, paddingTop ?? 0, paddingRight ?? 0, paddingBottom ?? 0);

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
