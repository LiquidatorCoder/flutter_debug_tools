import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/flutter_debug_tools_version.dart';
import 'package:flutter_debug_tools/src/utils/dart_runtime_info.dart';
import 'package:flutter_debug_tools/src/utils/shared_prefs_manager.dart';
import 'package:flutter_debug_tools/src/view/flutter_lens_theme.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel_sheet.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel_styles.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DebugToolsPanel extends StatefulWidget {
  final Color? color;
  final VoidCallback onClose;
  final VoidCallback toggleLogs;
  final VoidCallback toggleNetworkInspector;
  final VoidCallback toggleColorPicker;
  final VoidCallback clearColor;
  final VoidCallback toggleDeviceDetails;
  final VoidCallback toggleAnimationToolbox;

  const DebugToolsPanel({
    super.key,
    this.color,
    required this.onClose,
    required this.toggleLogs,
    required this.toggleNetworkInspector,
    required this.toggleColorPicker,
    required this.clearColor,
    required this.toggleDeviceDetails,
    required this.toggleAnimationToolbox,
  });

  @override
  State<DebugToolsPanel> createState() => _DebugToolsPanelState();
}

class _DebugToolsPanelState extends State<DebugToolsPanel> with SingleTickerProviderStateMixin {
  late bool _debugPaintEnabled;
  late bool _repaintRainbowEnabled;
  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlideAnimation;
  late final Animation<double> _sheetOpacityAnimation;
  late final Animation<double> _barrierOpacityAnimation;
  bool _isDismissing = false;
  String _appVersion = 'loading';
  final String _debugToolsVersion = flutterDebugToolsVersion;
  String _flutterVersion = 'loading';
  String _dartVersion = 'loading';

  static const double _dismissVelocity = 700;
  static const double _dismissProgress = 0.72;

  @override
  void initState() {
    super.initState();
    _debugPaintEnabled = debugPaintSizeEnabled;
    _repaintRainbowEnabled = debugRepaintTextRainbowEnabled;

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _sheetSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _sheetController,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        reverseCurve: Curves.easeOutCubic,
      ),
    );

    _sheetOpacityAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _barrierOpacityAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    _loadVersions();
    _sheetController.forward();
  }

  Future<void> _loadVersions() async {
    final String dartVersion = getDartRuntimeVersion();

    const String flutterVersion = String.fromEnvironment(
      'FLUTTER_VERSION',
      defaultValue: 'unknown',
    );

    String appVersion = 'unknown';
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _dartVersion = dartVersion;
      _flutterVersion = flutterVersion;
      _appVersion = appVersion;
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  String _colorToHexString(Color color, {bool withAlpha = false}) {
    String channelToHex(double value) => (value * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');

    final a = channelToHex(color.a);
    final r = channelToHex(color.r);
    final g = channelToHex(color.g);
    final b = channelToHex(color.b);

    return withAlpha ? '#$a$r$g$b' : '#$r$g$b';
  }

  Future<void> _dismiss({VoidCallback? onDismissed, bool closePanel = true}) async {
    if (_isDismissing) return;
    _isDismissing = true;

    await _sheetController.reverse();
    if (!mounted) return;

    if (onDismissed != null) {
      onDismissed();
      return;
    }

    if (closePanel) {
      widget.onClose();
    }
  }

  void _handleSheetDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (_isDismissing) return;
    final double delta = details.primaryDelta ?? 0;
    if (delta <= 0) return;

    final double sheetTravel = MediaQuery.sizeOf(context).height * 0.82;
    if (sheetTravel <= 0) return;
    final double progressDelta = delta / sheetTravel;

    _sheetController.value = (_sheetController.value - progressDelta).clamp(0.0, 1.0);
  }

  void _handleSheetDragEnd(DragEndDetails details) {
    if (_isDismissing) return;

    final double velocity = details.primaryVelocity ?? 0;
    if (velocity > _dismissVelocity || _sheetController.value < _dismissProgress) {
      _dismiss();
      return;
    }

    _sheetController.forward();
  }

  void _toggleDebugPaint() {
    setState(() {
      _debugPaintEnabled = !_debugPaintEnabled;
      debugPaintSizeEnabled = _debugPaintEnabled;
    });
    SharedPrefsManager.instance.setBool("debugPaintSizeEnabled", debugPaintSizeEnabled);
  }

  void _toggleRenderBoxDetails() {
    state.value = state.value.copyWith(
      shouldShowRenderBoxDetails: !state.value.shouldShowRenderBoxDetails,
    );
    SharedPrefsManager.instance.setBool(
      "shouldShowRenderBoxDetails",
      state.value.shouldShowRenderBoxDetails,
    );
    _dismiss();
  }

  void _toggleRepaintRainbow() {
    setState(() {
      _repaintRainbowEnabled = !_repaintRainbowEnabled;
      debugRepaintTextRainbowEnabled = _repaintRainbowEnabled;
    });
    SharedPrefsManager.instance.setBool(
      "debugRepaintTextRainbowEnabled",
      debugRepaintTextRainbowEnabled,
    );
  }

  void _togglePerfOverlay() {
    state.value = state.value.copyWith(
      shouldShowPerformanceOverlay: !state.value.shouldShowPerformanceOverlay,
    );
    SharedPrefsManager.instance.setBool(
      "showPerformanceOverlay",
      state.value.shouldShowPerformanceOverlay,
    );
    setState(() {});
  }

  void _toggleScreenNameDetails() {
    state.value = state.value.copyWith(
      shouldShowScreenName: !state.value.shouldShowScreenName,
    );
    SharedPrefsManager.instance.setBool("shouldShowScreenName", state.value.shouldShowScreenName);
    setState(() {});
  }

  List<DebugToolItem> _buildToolItems() {
    final bool hasAnimationOverrides =
        state.value.animationSpeedFactor != DebugToolsState.defaultAnimationSpeedFactor ||
            state.value.animationCurvePreset != AnimationCurvePreset.system ||
            state.value.shouldPauseAnimations ||
            state.value.shouldDisableAnimations ||
            state.value.shouldShowFrameTimingHud ||
            state.value.shouldShowAnimationHighlights ||
            state.value.shouldUseAnimationHighlightCompatibility;

    return [
      DebugToolItem(
        id: 'debug_paint',
        label: 'Debug\nPaint',
        icon: Icons.grid_4x4_rounded,
        isActive: _debugPaintEnabled,
        onTap: _toggleDebugPaint,
      ),
      DebugToolItem(
        id: 'size_info',
        label: 'Size\nInfo',
        icon: Icons.swap_vert_rounded,
        isActive: state.value.shouldShowRenderBoxDetails,
        onTap: _toggleRenderBoxDetails,
      ),
      DebugToolItem(
        id: 'repaint_rainbow',
        label: 'Repaint\nRainbow',
        icon: Icons.auto_awesome_rounded,
        isActive: _repaintRainbowEnabled,
        onTap: _toggleRepaintRainbow,
      ),
      DebugToolItem(
        id: 'debug_logs',
        label: 'Debug\nLogs',
        icon: Icons.notes_rounded,
        isActive: false,
        onTap: widget.toggleLogs,
      ),
      DebugToolItem(
        id: 'perf_overlay',
        label: 'Perf\nOverlay',
        icon: Icons.monitor_heart_rounded,
        isActive: state.value.shouldShowPerformanceOverlay,
        onTap: _togglePerfOverlay,
      ),
      DebugToolItem(
        id: 'color_picker',
        label: 'Color\nPicker',
        icon: Icons.opacity_outlined,
        isActive: false,
        onTap: () => _dismiss(
          onDismissed: widget.toggleColorPicker,
          closePanel: false,
        ),
      ),
      DebugToolItem(
        id: 'device_details',
        label: 'Device\nDetails',
        icon: Icons.stay_current_portrait_outlined,
        isActive: false,
        onTap: widget.toggleDeviceDetails,
      ),
      DebugToolItem(
        id: 'screen_name',
        label: 'Screen\nName',
        icon: Icons.login_rounded,
        isActive: state.value.shouldShowScreenName,
        onTap: _toggleScreenNameDetails,
      ),
      DebugToolItem(
        id: 'animation_toolbox',
        label: 'Animation\nToolbox',
        icon: Icons.animation_rounded,
        isActive: state.value.shouldShowAnimationToolbox || hasAnimationOverrides,
        onTap: widget.toggleAnimationToolbox,
      ),
      DebugToolItem(
        id: 'network_inspector',
        label: 'Network\nInspector',
        icon: Icons.wifi_tethering_rounded,
        isActive: false,
        onTap: widget.toggleNetworkInspector,
      ),
    ];
  }

  List<DevTickerItem> _buildTickerItems() {
    const String buildMode = kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug';

    return [
      DevTickerItem(
        label: 'App',
        value: _appVersion,
        dotColor: DevTickerDotColor.green,
      ),
      DevTickerItem(
        label: 'FlutterLens',
        value: _debugToolsVersion,
        dotColor: DevTickerDotColor.orange,
      ),
      DevTickerItem(label: 'Flutter', value: _flutterVersion),
      DevTickerItem(label: 'Dart', value: _dartVersion),
      const DevTickerItem(
        label: 'Build',
        value: buildMode,
        dotColor: DevTickerDotColor.pink,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: flutterLensTheme(context),
      child: GestureDetector(
        onTap: _dismiss,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: _barrierOpacityAnimation,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: ColoredBox(
                            color: DebugToolsPanelStyles.sheetFill.withValues(alpha: 0.45),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (details) => _handleSheetDragUpdate(details, context),
                    onVerticalDragEnd: _handleSheetDragEnd,
                    child: DebugToolsPanelSheet(
                      opacityAnimation: _sheetOpacityAnimation,
                      slideAnimation: _sheetSlideAnimation,
                      selectedColor: widget.color,
                      colorToHexString: _colorToHexString,
                      onClearColor: () => _dismiss(
                        onDismissed: widget.clearColor,
                        closePanel: false,
                      ),
                      toolItems: _buildToolItems(),
                      tickerItems: _buildTickerItems(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
