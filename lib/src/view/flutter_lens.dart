import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_debug_tools/src/animation_curve_override.dart';
import 'package:flutter_debug_tools/src/debug_log_store.dart';
import 'package:flutter_debug_tools/src/debug_network_capture.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/utils/shared_prefs_manager.dart';
import 'package:flutter_debug_tools/src/view/debug_animation_highlight_compat_overlay.dart';
import 'package:flutter_debug_tools/src/view/debug_animation_highlight_overlay.dart';
import 'package:flutter_debug_tools/src/view/debug_animation_toolbox_sheet.dart';
import 'package:flutter_debug_tools/src/view/debug_device_details_dialog.dart';
import 'package:flutter_debug_tools/src/view/debug_frame_timing_hud.dart';
import 'package:flutter_debug_tools/src/view/debug_indicator.dart';
import 'package:flutter_debug_tools/src/view/debug_logs_viewer.dart';
import 'package:flutter_debug_tools/src/view/debug_network_viewer.dart';
import 'package:flutter_debug_tools/src/view/debug_screen_details_widget.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel.dart';
import 'package:flutter_debug_tools/src/view/pixel_color_inspector.dart';
import 'package:flutter_debug_tools/src/view/render_box_inspector.dart';

/// FlutterLens overlays debugging tools over its [child].
class FlutterLens extends StatefulWidget {
  final Widget Function(BuildContext context, bool value, Widget? child) builder;
  final Widget? child;
  final bool isEnabled;

  const FlutterLens({
    super.key,
    this.child,
    this.isEnabled = kDebugMode,
    required this.builder,
  });

  @override
  State<FlutterLens> createState() => _FlutterLensState();
}

class _FlutterLensState extends State<FlutterLens> with WidgetsBindingObserver {
  double _appliedTimeDilation = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DebugLogCapture.install();
    installDebugNetworkCapture();
  }

  @override
  void dispose() {
    timeDilation = 1.0;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (state.value.shouldShowLogsScreen) {
      _toggleLogs();
      return true;
    }

    if (state.value.shouldShowNetworkScreen) {
      _toggleNetworkInspector();
      return true;
    }

    if (state.value.shouldShowDeviceDetails) {
      _toggleDeviceDetails();
      return true;
    }

    if (state.value.shouldShowAnimationToolbox) {
      _toggleAnimationToolbox();
      return true;
    }

    return false;
  }

  void _toggleDialog() => state.value = state.value.copyWith(shouldShowToolsPanel: !state.value.shouldShowToolsPanel);
  void _toggleLogs() => state.value = state.value.copyWith(shouldShowLogsScreen: !state.value.shouldShowLogsScreen);
  void _toggleNetworkInspector() =>
      state.value = state.value.copyWith(shouldShowNetworkScreen: !state.value.shouldShowNetworkScreen);
  void _toggleColorPicker() =>
      state.value = state.value.copyWith(shouldShowColorPicker: !state.value.shouldShowColorPicker);
  void _toggleDeviceDetails() =>
      state.value = state.value.copyWith(shouldShowDeviceDetails: !state.value.shouldShowDeviceDetails);
  void _toggleAnimationToolbox() =>
      state.value = state.value.copyWith(shouldShowAnimationToolbox: !state.value.shouldShowAnimationToolbox);

  void _setAnimationSpeed(double speed) {
    final clamped = speed.clamp(0.25, 2.0);
    state.value = state.value.copyWith(animationSpeedFactor: clamped);
    SharedPrefsManager.instance.setDouble('animationSpeedFactor', clamped);
  }

  void _setAnimationCurvePreset(AnimationCurvePreset preset) {
    state.value = state.value.copyWith(animationCurvePreset: preset);
    SharedPrefsManager.instance.setString('animationCurvePreset', preset.id);
  }

  void _setPauseAnimations(bool value) {
    state.value = state.value.copyWith(shouldPauseAnimations: value);
    SharedPrefsManager.instance.setBool('shouldPauseAnimations', value);
  }

  void _setDisableAnimations(bool value) {
    state.value = state.value.copyWith(shouldDisableAnimations: value);
    SharedPrefsManager.instance.setBool('shouldDisableAnimations', value);
  }

  void _setFrameTimingHud(bool value) {
    state.value = state.value.copyWith(shouldShowFrameTimingHud: value);
    SharedPrefsManager.instance.setBool('shouldShowFrameTimingHud', value);
  }

  void _setAnimationHighlights(bool value) {
    if (!value) {
      state.value = state.value.copyWith(
        shouldShowAnimationHighlights: false,
        shouldUseAnimationHighlightCompatibility: false,
        animationHighlightUnavailableReason: null,
      );
      SharedPrefsManager.instance.setBool('shouldShowAnimationHighlights', false);
      return;
    }

    final String? knownUnsafeReason = _knownUnsafeHighlightReason();
    if (knownUnsafeReason != null) {
      state.value = state.value.copyWith(
        shouldShowAnimationHighlights: false,
        shouldUseAnimationHighlightCompatibility: true,
        animationHighlightUnavailableReason: knownUnsafeReason,
      );
      SharedPrefsManager.instance.setBool('shouldShowAnimationHighlights', true);
      return;
    }

    state.value = state.value.copyWith(
      shouldShowAnimationHighlights: true,
      shouldUseAnimationHighlightCompatibility: false,
      animationHighlightUnavailableReason: null,
    );
    SharedPrefsManager.instance.setBool('shouldShowAnimationHighlights', true);
  }

  String? _knownUnsafeHighlightReason() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    final data = state.value.deviceData;
    final sdk = int.tryParse((data['SDK Version']?.toString() ?? '').trim());

    if (sdk != null && sdk <= 31) {
      return 'Animation highlight is disabled on Android 12 and below due to a known Impeller crash risk.';
    }

    return null;
  }

  void _disableAnimationHighlightFromRuntime(String reason) {
    if (!state.value.shouldShowAnimationHighlights && state.value.animationHighlightUnavailableReason == reason) {
      return;
    }

    state.value = state.value.copyWith(
      shouldShowAnimationHighlights: false,
      shouldUseAnimationHighlightCompatibility: true,
      animationHighlightUnavailableReason: reason,
    );
    SharedPrefsManager.instance.setBool('shouldShowAnimationHighlights', true);
  }

  void _setAnimationHighlightSensitivity(double value) {
    final clamped = value.clamp(5.0, 60.0);
    state.value = state.value.copyWith(animationHighlightSensitivity: clamped);
    SharedPrefsManager.instance.setDouble('animationHighlightSensitivity', clamped);
  }

  void _setAnimationHighlightInterval(int value) {
    final clamped = value.clamp(60, 400);
    state.value = state.value.copyWith(animationHighlightIntervalMs: clamped);
    SharedPrefsManager.instance.setInt('animationHighlightIntervalMs', clamped);
  }

  void _setAnimationHighlightDecay(int value) {
    final clamped = value.clamp(150, 1500);
    state.value = state.value.copyWith(animationHighlightDecayMs: clamped);
    SharedPrefsManager.instance.setInt('animationHighlightDecayMs', clamped);
  }

  void _setAnimationHighlightOpacity(double value) {
    final clamped = value.clamp(0.1, 0.9);
    state.value = state.value.copyWith(animationHighlightOpacity: clamped);
    SharedPrefsManager.instance.setDouble('animationHighlightOpacity', clamped);
  }

  void _resetAnimationToolboxSettings() {
    state.value = state.value.resetAnimationToolboxSettings();
    SharedPrefsManager.instance.setDouble('animationSpeedFactor', DebugToolsState.defaultAnimationSpeedFactor);
    SharedPrefsManager.instance.setBool('shouldPauseAnimations', false);
    SharedPrefsManager.instance.setBool('shouldDisableAnimations', false);
    SharedPrefsManager.instance.setBool('shouldShowAnimationHighlights', false);
    SharedPrefsManager.instance
        .setDouble('animationHighlightSensitivity', DebugToolsState.defaultAnimationHighlightSensitivity);
    SharedPrefsManager.instance
        .setInt('animationHighlightIntervalMs', DebugToolsState.defaultAnimationHighlightIntervalMs);
    SharedPrefsManager.instance.setInt('animationHighlightDecayMs', DebugToolsState.defaultAnimationHighlightDecayMs);
    SharedPrefsManager.instance
        .setDouble('animationHighlightOpacity', DebugToolsState.defaultAnimationHighlightOpacity);
    SharedPrefsManager.instance.setString('animationCurvePreset', AnimationCurvePreset.system.id);
    SharedPrefsManager.instance.setBool('shouldShowFrameTimingHud', false);
  }

  Curve? _resolveOverrideCurve(AnimationCurvePreset preset) {
    switch (preset) {
      case AnimationCurvePreset.system:
        return null;
      case AnimationCurvePreset.linear:
        return Curves.linear;
      case AnimationCurvePreset.easeIn:
        return Curves.easeIn;
      case AnimationCurvePreset.easeOut:
        return Curves.easeOut;
      case AnimationCurvePreset.easeInOut:
        return Curves.easeInOut;
      case AnimationCurvePreset.easeInCubic:
        return Curves.easeInCubic;
      case AnimationCurvePreset.easeOutCubic:
        return Curves.easeOutCubic;
      case AnimationCurvePreset.easeInOutCubic:
        return Curves.easeInOutCubic;
      case AnimationCurvePreset.fastOutSlowIn:
        return Curves.fastOutSlowIn;
      case AnimationCurvePreset.decelerate:
        return Curves.decelerate;
      case AnimationCurvePreset.bounceIn:
        return Curves.bounceIn;
      case AnimationCurvePreset.bounceOut:
        return Curves.bounceOut;
      case AnimationCurvePreset.bounceInOut:
        return Curves.bounceInOut;
      case AnimationCurvePreset.elasticOut:
        return Curves.elasticOut;
      case AnimationCurvePreset.easeOutBack:
        return Curves.easeOutBack;
    }
  }

  void _syncTimeDilation(DebugToolsState value) {
    final target = (1.0 / value.animationSpeedFactor).clamp(0.5, 4.0);
    if ((target - _appliedTimeDilation).abs() < 0.001) {
      return;
    }

    timeDilation = target;
    _appliedTimeDilation = target;
  }

  Widget _buildInstrumentedApp(BuildContext context, DebugToolsState value, Widget? child) {
    bool highlightEnabled = value.shouldShowAnimationHighlights;
    if (highlightEnabled && !kIsWeb && defaultTargetPlatform == TargetPlatform.android && value.deviceData.isEmpty) {
      highlightEnabled = false;
    } else {
      final String? knownUnsafeReason = _knownUnsafeHighlightReason();
      if (highlightEnabled && knownUnsafeReason != null) {
        highlightEnabled = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _disableAnimationHighlightFromRuntime(knownUnsafeReason);
          }
        });
      }
    }

    Widget content = widget.builder(context, value.shouldShowPerformanceOverlay, child);
    final mediaQuery = MediaQuery.maybeOf(context);

    if (mediaQuery != null) {
      content = MediaQuery(
        data: mediaQuery.copyWith(disableAnimations: value.shouldDisableAnimations),
        child: content,
      );
    }

    content = TickerMode(
      enabled: !value.shouldPauseAnimations,
      child: content,
    );

    content = DebugAnimationHighlightOverlay(
      isEnabled: highlightEnabled,
      sensitivity: value.animationHighlightSensitivity,
      sampleInterval: Duration(milliseconds: value.animationHighlightIntervalMs),
      decayDuration: Duration(milliseconds: value.animationHighlightDecayMs),
      opacity: value.animationHighlightOpacity,
      onUnavailable: _disableAnimationHighlightFromRuntime,
      child: content,
    );

    content = DebugAnimationHighlightCompatOverlay(
      isEnabled: value.shouldUseAnimationHighlightCompatibility,
      opacity: value.animationHighlightOpacity,
      child: content,
    );

    content = DebugFrameTimingHud(
      isEnabled: value.shouldShowFrameTimingHud,
      child: content,
    );

    content = FlutterLensAnimationCurveScope(
      overrideCurve: _resolveOverrideCurve(value.animationCurvePreset),
      child: content,
    );

    return content;
  }

  String colorToHexString(Color color, {bool withAlpha = false}) {
    String channelToHex(double value) => (value * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');

    final a = channelToHex(color.a);
    final r = channelToHex(color.r);
    final g = channelToHex(color.g);
    final b = channelToHex(color.b);

    if (withAlpha) {
      return '#$a$r$g$b';
    }

    return '#$r$g$b';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      if (_appliedTimeDilation != 1.0) {
        timeDilation = 1.0;
        _appliedTimeDilation = 1.0;
      }
      return widget.builder(context, false, widget.child);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<DebugToolsState>(
        valueListenable: state,
        builder: (context, value, child) {
          _syncTimeDilation(value);
          final Widget instrumentedApp = _buildInstrumentedApp(context, value, child);

          return PopScope(
            canPop: !(value.shouldShowLogsScreen ||
                value.shouldShowNetworkScreen ||
                value.shouldShowAnimationToolbox ||
                value.shouldShowDeviceDetails),
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && value.shouldShowLogsScreen) {
                _toggleLogs();
              } else if (!didPop && value.shouldShowNetworkScreen) {
                _toggleNetworkInspector();
              } else if (!didPop && value.shouldShowAnimationToolbox) {
                _toggleAnimationToolbox();
              } else if (!didPop && value.shouldShowDeviceDetails) {
                _toggleDeviceDetails();
              }
            },
            child: Stack(
              children: [
                if (value.shouldShowColorPicker)
                  PixelColorInspector(
                    child: (value.shouldShowRenderBoxDetails)
                        ? RenderBoxInspector(child: instrumentedApp)
                        : instrumentedApp,
                    onColorPicked: (val) {
                      state.value = state.value.copyWith(currentColor: val);
                      _toggleColorPicker();
                      _toggleDialog();
                    },
                  )
                else
                  (value.shouldShowRenderBoxDetails) ? RenderBoxInspector(child: instrumentedApp) : instrumentedApp,
                if (value.shouldShowToolsIndicator) DebugIndicator(toggleTools: _toggleDialog),
                if (value.shouldShowToolsPanel)
                  DebugToolsPanel(
                    color: value.currentColor,
                    onClose: _toggleDialog,
                    toggleLogs: _toggleLogs,
                    toggleNetworkInspector: _toggleNetworkInspector,
                    toggleColorPicker: () {
                      _toggleColorPicker();
                      _toggleDialog();
                    },
                    clearColor: () {
                      Clipboard.setData(ClipboardData(text: colorToHexString(value.currentColor ?? Colors.white)));
                      state.value = state.value.clearColor();
                      _toggleDialog();
                    },
                    toggleDeviceDetails: _toggleDeviceDetails,
                    toggleAnimationToolbox: _toggleAnimationToolbox,
                  ),
                if (value.shouldShowScreenName)
                  DebugScreenDetailsWidget(
                    screenName: value.currentScreen ?? '',
                  ),
                if (value.shouldShowDeviceDetails)
                  DebugDeviceDetailsDialog(
                    onTap: _toggleDeviceDetails,
                  ),
                if (value.shouldShowLogsScreen) DebugLogsViewer(onTap: _toggleLogs),
                if (value.shouldShowNetworkScreen) DebugNetworkViewer(onTap: _toggleNetworkInspector),
                if (value.shouldShowAnimationToolbox)
                  Positioned.fill(
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (context) => ValueListenableBuilder<DebugToolsState>(
                            valueListenable: state,
                            builder: (context, liveValue, _) => DebugAnimationToolboxSheet(
                              stateValue: liveValue,
                              onClose: _toggleAnimationToolbox,
                              onReset: _resetAnimationToolboxSettings,
                              onAnimationSpeedChanged: _setAnimationSpeed,
                              onAnimationCurvePresetChanged: _setAnimationCurvePreset,
                              onPauseAnimationsChanged: _setPauseAnimations,
                              onDisableAnimationsChanged: _setDisableAnimations,
                              onFrameTimingHudChanged: _setFrameTimingHud,
                              onHighlightAnimationsChanged: _setAnimationHighlights,
                              onHighlightSensitivityChanged: _setAnimationHighlightSensitivity,
                              onHighlightIntervalChanged: _setAnimationHighlightInterval,
                              onHighlightDecayChanged: _setAnimationHighlightDecay,
                              onHighlightOpacityChanged: _setAnimationHighlightOpacity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
