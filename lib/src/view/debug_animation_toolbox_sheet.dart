import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel_styles.dart';
import 'package:flutter_debug_tools/src/view/flutter_lens_theme.dart';

class DebugAnimationToolboxSheet extends StatelessWidget {
  const DebugAnimationToolboxSheet({
    super.key,
    required this.stateValue,
    required this.onClose,
    required this.onReset,
    required this.onAnimationSpeedChanged,
    required this.onAnimationCurvePresetChanged,
    required this.onPauseAnimationsChanged,
    required this.onDisableAnimationsChanged,
    required this.onHighlightAnimationsChanged,
    required this.onHighlightSensitivityChanged,
    required this.onHighlightIntervalChanged,
    required this.onHighlightDecayChanged,
    required this.onHighlightOpacityChanged,
  });

  final DebugToolsState stateValue;
  final VoidCallback onClose;
  final VoidCallback onReset;
  final ValueChanged<double> onAnimationSpeedChanged;
  final ValueChanged<AnimationCurvePreset> onAnimationCurvePresetChanged;
  final ValueChanged<bool> onPauseAnimationsChanged;
  final ValueChanged<bool> onDisableAnimationsChanged;
  final ValueChanged<bool> onHighlightAnimationsChanged;
  final ValueChanged<double> onHighlightSensitivityChanged;
  final ValueChanged<int> onHighlightIntervalChanged;
  final ValueChanged<int> onHighlightDecayChanged;
  final ValueChanged<double> onHighlightOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: flutterLensTheme(context),
      child: Scaffold(
        backgroundColor: DebugToolsPanelStyles.sheetFill,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(
                      'Animation Toolbox',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: DebugToolsPanelStyles.textPrimary,
                        fontFamily: flutterLensFontFamily,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _TextActionButton(
                    label: 'Reset',
                    onTap: onReset,
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconButton(
                    icon: Icons.clear_rounded,
                    onTap: onClose,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _SectionCard(
                      title: 'GLOBAL CONTROLS',
                      icon: Icons.tune_rounded,
                      accentColor: const Color(0xFFF7A250),
                      child: Column(
                        children: [
                          _SliderTile(
                            label: 'Animation Speed',
                            description: 'Scales app animation duration globally (lower is slower, higher is faster).',
                            valueLabel: '${stateValue.animationSpeedFactor.toStringAsFixed(2)}x',
                            min: 0.25,
                            max: 2.0,
                            divisions: 35,
                            value: stateValue.animationSpeedFactor,
                            onChanged: onAnimationSpeedChanged,
                          ),
                          const SizedBox(height: 10),
                          _SwitchTile(
                            title: 'Pause Animations',
                            subtitle: 'Stops active tickers app-wide.',
                            value: stateValue.shouldPauseAnimations,
                            onChanged: onPauseAnimationsChanged,
                          ),
                          const SizedBox(height: 8),
                          _SwitchTile(
                            title: 'Disable Animations',
                            subtitle: 'Requests reduced motion behavior.',
                            value: stateValue.shouldDisableAnimations,
                            onChanged: onDisableAnimationsChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'ANIMATION HIGHLIGHT',
                      icon: Icons.blur_on_rounded,
                      accentColor: const Color(0xFFE24A79),
                      child: Column(
                        children: [
                          _SwitchTile(
                            title: 'Highlight Animated Regions',
                            subtitle: stateValue.shouldUseAnimationHighlightCompatibility
                                ? 'Compatibility mode: shows frame activity safely.'
                                : 'Shows a heatmap where frames change.',
                            value: stateValue.shouldShowAnimationHighlights ||
                                stateValue.shouldUseAnimationHighlightCompatibility,
                            onChanged: onHighlightAnimationsChanged,
                          ),
                          if (stateValue.animationHighlightUnavailableReason != null) ...[
                            const SizedBox(height: 8),
                            _NoticeTile(
                              message: stateValue.animationHighlightUnavailableReason!,
                            ),
                          ],
                          const SizedBox(height: 10),
                          _SliderTile(
                            label: 'Sensitivity',
                            description: 'Controls how much pixel change is needed before a region is highlighted.',
                            valueLabel: stateValue.animationHighlightSensitivity.toStringAsFixed(0),
                            min: 5,
                            max: 60,
                            divisions: 55,
                            value: stateValue.animationHighlightSensitivity,
                            onChanged: onHighlightSensitivityChanged,
                          ),
                          const SizedBox(height: 10),
                          _SliderTile(
                            label: 'Sample Interval',
                            description:
                                'How often highlight sampling runs (lower is more responsive, higher is lighter).',
                            valueLabel: '${stateValue.animationHighlightIntervalMs}ms',
                            min: 60,
                            max: 400,
                            divisions: 34,
                            value: stateValue.animationHighlightIntervalMs.toDouble(),
                            onChanged: (value) => onHighlightIntervalChanged(value.round()),
                          ),
                          const SizedBox(height: 10),
                          _SliderTile(
                            label: 'Trail Decay',
                            description: 'How long highlighted regions remain visible before fading out.',
                            valueLabel: '${stateValue.animationHighlightDecayMs}ms',
                            min: 150,
                            max: 1500,
                            divisions: 45,
                            value: stateValue.animationHighlightDecayMs.toDouble(),
                            onChanged: (value) => onHighlightDecayChanged(value.round()),
                          ),
                          const SizedBox(height: 10),
                          _SliderTile(
                            label: 'Overlay Opacity',
                            description: 'Adjusts visibility strength of the highlight overlay on top of your UI.',
                            valueLabel: stateValue.animationHighlightOpacity.toStringAsFixed(2),
                            min: 0.1,
                            max: 0.9,
                            divisions: 40,
                            value: stateValue.animationHighlightOpacity,
                            onChanged: onHighlightOpacityChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'GLOBAL CURVES OVERRIDE',
                      icon: Icons.multiline_chart_rounded,
                      accentColor: const Color(0xFFE24A79),
                      child: _CurvePresetSelector(
                        selected: stateValue.animationCurvePreset,
                        onChanged: onAnimationCurvePresetChanged,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'TICKER INSPECTOR',
                      icon: Icons.query_stats_rounded,
                      accentColor: const Color(0xFF4ADE80),
                      child: _TickerInspector(
                        stateValue: stateValue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurvePresetSelector extends StatefulWidget {
  const _CurvePresetSelector({
    required this.selected,
    required this.onChanged,
  });

  final AnimationCurvePreset selected;
  final ValueChanged<AnimationCurvePreset> onChanged;

  @override
  State<_CurvePresetSelector> createState() => _CurvePresetSelectorState();
}

class _CurvePresetSelectorState extends State<_CurvePresetSelector> with SingleTickerProviderStateMixin {
  late final AnimationController _previewController;

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _previewController,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Affects animations that opt into FlutterLens curve scope.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontFamily: flutterLensFontFamily,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  for (final preset in AnimationCurvePreset.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CurvePresetRow(
                        label: preset.label,
                        curve: _curveForPreset(preset),
                        progress: _previewController.value,
                        isSelected: preset == widget.selected,
                        onTap: () => widget.onChanged(preset),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Curve _curveForPreset(AnimationCurvePreset preset) {
    switch (preset) {
      case AnimationCurvePreset.system:
        return Curves.easeInOut;
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
}

class _CurvePresetRow extends StatelessWidget {
  const _CurvePresetRow({
    required this.label,
    required this.curve,
    required this.progress,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Curve curve;
  final double progress;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE24A79);
    final curvedValue = curve.transform(progress).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: isSelected ? accent.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? accent : Colors.white.withValues(alpha: 0.75),
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                height: 18,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 2,
                      width: 84,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    Positioned(
                      left: curvedValue * 68,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isSelected ? accent : Colors.white.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: DebugToolsPanelStyles.sheetFill,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.22),
                            accentColor.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                      ),
                      child: Icon(icon, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: accentColor.withValues(alpha: 0.85),
                        fontFamily: flutterLensFontFamily,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 14),
                  child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 18, color: DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class _TextActionButton extends StatelessWidget {
  const _TextActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white.withValues(alpha: 0.8),
              fontFamily: flutterLensFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFE24A79);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accent.withValues(alpha: 0.45);
              }
              return Colors.white.withValues(alpha: 0.18);
            }),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accent;
              }
              return Colors.white.withValues(alpha: 0.9);
            }),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.description,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final String valueLabel;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFE24A79);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.72),
                  fontFamily: flutterLensFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
                fontFamily: flutterLensFontFamily,
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.18),
              valueIndicatorColor: accent,
            ),
            child: Slider(
              min: min,
              max: max,
              divisions: divisions,
              value: value.clamp(min, max),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x26F7A250),
        border: Border.all(color: const Color(0x66F7A250)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF7A250)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 10,
                height: 1.35,
                color: Color(0xFFF7CBA1),
                fontFamily: flutterLensFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerInspector extends StatefulWidget {
  const _TickerInspector({required this.stateValue});

  final DebugToolsState stateValue;

  @override
  State<_TickerInspector> createState() => _TickerInspectorState();
}

class _TickerInspectorState extends State<_TickerInspector> {
  Timer? _pollTimer;
  int _transientCallbacks = 0;
  bool _hasScheduledFrame = false;

  @override
  void initState() {
    super.initState();
    _captureSnapshot();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      _captureSnapshot();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _captureSnapshot() {
    final scheduler = SchedulerBinding.instance;
    final nextTransient = scheduler.transientCallbackCount;
    final nextHasScheduledFrame = scheduler.hasScheduledFrame;

    if (nextTransient == _transientCallbacks && nextHasScheduledFrame == _hasScheduledFrame) {
      return;
    }

    setState(() {
      _transientCallbacks = nextTransient;
      _hasScheduledFrame = nextHasScheduledFrame;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool tickerPaused = widget.stateValue.shouldPauseAnimations;
    final bool compatMode = widget.stateValue.shouldUseAnimationHighlightCompatibility;

    final String statusLabel;
    final Color statusColor;
    if (tickerPaused) {
      statusLabel = 'Paused by TickerMode';
      statusColor = const Color(0xFFF7A250);
    } else if (_transientCallbacks > 0 || _hasScheduledFrame) {
      statusLabel = 'Animations active';
      statusColor = const Color(0xFF4ADE80);
    } else {
      statusLabel = 'Idle';
      statusColor = const Color(0xFF9EA3AD);
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Basic Runtime Snapshot',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: flutterLensFontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InspectorRow(
                label: 'Transient Callbacks',
                value: '$_transientCallbacks',
                note: 'Estimated active ticker/controller work this frame.',
              ),
              const SizedBox(height: 8),
              _InspectorRow(
                label: 'Scheduled Frame',
                value: _hasScheduledFrame ? 'Yes' : 'No',
                note: 'Whether the scheduler is requesting a new frame.',
              ),
              const SizedBox(height: 8),
              _InspectorRow(
                label: 'Global TickerMode',
                value: tickerPaused ? 'Paused' : 'Running',
                note: 'Controlled by Pause Animations toggle.',
              ),
              const SizedBox(height: 8),
              _InspectorRow(
                label: 'Highlight Engine',
                value: compatMode ? 'Compatibility' : 'Heatmap',
                note: compatMode ? 'Safe mode on this device/renderer.' : 'Per-region motion heatmap sampling.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFamily: flutterLensFontFamily,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: flutterLensFontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: flutterLensFontFamily,
          ),
        ),
      ],
    );
  }
}
