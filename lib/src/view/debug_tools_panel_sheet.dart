import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/src/view/flutter_lens_theme.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel_styles.dart';

class DebugToolItem {
  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const DebugToolItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });
}

enum DevTickerDotColor { neutral, green, orange, pink }

class DevTickerItem {
  final String label;
  final String value;
  final DevTickerDotColor dotColor;

  const DevTickerItem({
    required this.label,
    required this.value,
    this.dotColor = DevTickerDotColor.neutral,
  });
}

class DebugToolsPanelSheet extends StatelessWidget {
  final Animation<double> opacityAnimation;
  final Animation<Offset> slideAnimation;
  final Color? selectedColor;
  final String Function(Color color) colorToHexString;
  final VoidCallback onClearColor;
  final List<DebugToolItem> toolItems;
  final List<DevTickerItem> tickerItems;

  const DebugToolsPanelSheet({
    super.key,
    required this.opacityAnimation,
    required this.slideAnimation,
    required this.selectedColor,
    required this.colorToHexString,
    required this.onClearColor,
    required this.toolItems,
    required this.tickerItems,
  });

  String _rgbText(Color color) {
    final int r = (color.r * 255).round().clamp(0, 255);
    final int g = (color.g * 255).round().clamp(0, 255);
    final int b = (color.b * 255).round().clamp(0, 255);
    return 'rgb($r, $g, $b)';
  }

  String _hslText(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final int h = hsl.hue.round();
    final int s = (hsl.saturation * 100).round();
    final int l = (hsl.lightness * 100).round();
    return 'hsl($h, $s%, $l%)';
  }

  @override
  Widget build(BuildContext context) {
    final bool showColorChip = selectedColor != null;

    return FadeTransition(
      opacity: opacityAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              decoration: const BoxDecoration(
                color: DebugToolsPanelStyles.sheetFill,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border.fromBorderSide(
                  BorderSide(color: Color.fromRGBO(255, 255, 255, 0.03), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.7),
                    blurRadius: 48,
                    offset: Offset(0, -12),
                  )
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Image(
                                    image: AssetImage(
                                      'assets/images/icon.png',
                                      package: 'flutter_debug_tools',
                                    ),
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const Image(
                                  image: AssetImage(
                                    'assets/images/icon.png',
                                    package: 'flutter_debug_tools',
                                  ),
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FlutterLens',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: DebugToolsPanelStyles.textPrimary,
                              fontFamily: flutterLensFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 0),
                            Color.fromRGBO(255, 255, 255, 0.04),
                            Color.fromRGBO(255, 255, 255, 0),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double cellWidth = (constraints.maxWidth - (12 * 3)) / 4;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 24,
                            children: toolItems
                                .map(
                                  (item) => SizedBox(
                                    width: cellWidth,
                                    child: _ToolButton(
                                      label: item.label,
                                      icon: item.icon,
                                      active: item.isActive,
                                      onTap: item.onTap,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                    if (showColorChip)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: _ColorResultCard(
                          color: selectedColor!,
                          hexText: colorToHexString(selectedColor!),
                          subText: '${_rgbText(selectedColor!)}  -  ${_hslText(selectedColor!)}',
                          onCopyTap: onClearColor,
                        ),
                      ),
                    _DevTickerRow(items: tickerItems),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorResultCard extends StatelessWidget {
  final Color color;
  final String hexText;
  final String subText;
  final VoidCallback onCopyTap;

  const _ColorResultCard({
    required this.color,
    required this.hexText,
    required this.subText,
    required this.onCopyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.06)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(38, 38, 42, 0.65),
            Color.fromRGBO(18, 18, 20, 0.65),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.10)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 18,
                ),
                const BoxShadow(
                  color: Color.fromRGBO(255, 255, 255, 0.20),
                  blurRadius: 1,
                  offset: Offset(0, -1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hexText.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: DebugToolsPanelStyles.textPrimary,
                        fontFamily: flutterLensFontFamily,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _ColorTag(label: 'HEX'),
                    const SizedBox(width: 4),
                    const _ColorTag(label: 'RGB'),
                    const SizedBox(width: 4),
                    const _ColorTag(label: 'HSL'),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DebugToolsPanelStyles.textSecondary,
                    letterSpacing: 0.2,
                    fontFamily: flutterLensFontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onCopyTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.05),
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Copy',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: Color.fromRGBO(255, 255, 255, 0.45),
                  fontFamily: flutterLensFontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorTag extends StatelessWidget {
  final String label;

  const _ColorTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.06)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Color.fromRGBO(255, 255, 255, 0.30),
          fontFamily: flutterLensFontFamily,
        ),
      ),
    );
  }
}

class _DevTickerRow extends StatefulWidget {
  final List<DevTickerItem> items;

  const _DevTickerRow({required this.items});

  @override
  State<_DevTickerRow> createState() => _DevTickerRowState();
}

class _DevTickerRowState extends State<_DevTickerRow> with SingleTickerProviderStateMixin {
  final GlobalKey _segmentKey = GlobalKey();
  late final AnimationController _marqueeController;

  static const double _pixelsPerSecond = 26;
  static const double _tickerHeight = 14;
  double _segmentExtent = 0;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndStart();
    });
  }

  @override
  void didUpdateWidget(covariant _DevTickerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _measureAndStart();
      });
    }
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  void _measureAndStart() {
    final BuildContext? segmentContext = _segmentKey.currentContext;
    if (segmentContext == null) return;
    final RenderBox? box = segmentContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final double extent = box.size.width;
    if (extent <= 0) return;
    if ((extent - _segmentExtent).abs() < 0.5 && _marqueeController.isAnimating) {
      return;
    }

    _segmentExtent = extent;
    final int durationMs = (_segmentExtent / _pixelsPerSecond * 1000).round().clamp(2000, 120000);
    _marqueeController.duration = Duration(milliseconds: durationMs);
    _marqueeController
      ..reset()
      ..repeat();
  }

  Color _dotColor(DevTickerDotColor color) {
    switch (color) {
      case DevTickerDotColor.green:
        return const Color(0xFF4ADE80);
      case DevTickerDotColor.orange:
        return const Color(0xFFF7A250);
      case DevTickerDotColor.pink:
        return const Color(0xFFE24A79);
      case DevTickerDotColor.neutral:
        return const Color.fromRGBO(255, 255, 255, 0.18);
    }
  }

  Widget _buildItem(DevTickerItem item) {
    final Color dot = _dotColor(item.dotColor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: dot,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: dot.withValues(alpha: 0.65), blurRadius: 2),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          item.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: Color.fromRGBO(255, 255, 255, 0.28),
            fontFamily: flutterLensFontFamily,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          item.value.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: Color.fromRGBO(255, 255, 255, 0.55),
            fontFamily: flutterLensFontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildTickerContent() {
    return Row(
      children: [
        for (int i = 0; i < widget.items.length; i++) ...[
          _buildItem(widget.items[i]),
          Container(
            width: 1,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color.fromRGBO(255, 255, 255, 0.07),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget measuredSegment = Row(
      key: _segmentKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTickerContent(),
      ],
    );
    final Widget duplicateSegment = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTickerContent(),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measureAndStart();
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.04)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: _tickerHeight,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _marqueeController,
            builder: (context, child) {
              final double dx = _segmentExtent <= 0 ? 0 : -_marqueeController.value * _segmentExtent;
              return Stack(
                children: [
                  Positioned(
                    left: dx,
                    top: 0,
                    bottom: 0,
                    child: measuredSegment,
                  ),
                  Positioned(
                    left: dx + _segmentExtent,
                    top: 0,
                    bottom: 0,
                    child: duplicateSegment,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _colorPulseAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.03), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );

    _colorPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _tapController.forward(from: 0);
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        widget.active ? DebugToolsPanelStyles.textPrimary : DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.45);
    final Color labelColor =
        widget.active ? DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.95) : DebugToolsPanelStyles.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.active)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: DebugToolsPanelStyles.accentGradient,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: widget.active ? null : DebugToolsPanelStyles.itemActive,
                          gradient: widget.active
                              ? DebugToolsPanelStyles.accentGradient
                              : const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    DebugToolsPanelStyles.itemStart,
                                    DebugToolsPanelStyles.itemEnd,
                                  ],
                                ),
                          border: Border.all(
                            color: widget.active
                                ? const Color.fromRGBO(255, 255, 255, 0.10)
                                : const Color.fromRGBO(255, 255, 255, 0.05),
                          ),
                          boxShadow: widget.active
                              ? const [
                                  BoxShadow(
                                    color: Color.fromRGBO(255, 255, 255, 0.08),
                                    blurRadius: 1,
                                    offset: Offset(0, -1),
                                  ),
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.25),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : const [
                                  BoxShadow(
                                    color: Color.fromRGBO(255, 255, 255, 0.05),
                                    blurRadius: 1,
                                    offset: Offset(0, -1),
                                  ),
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.4),
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: Icon(widget.icon, size: 24, color: iconColor),
                            ),
                            IgnorePointer(
                              child: Opacity(
                                opacity: _colorPulseAnimation.value * (widget.active ? 0.16 : 0.22),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: DebugToolsPanelStyles.accentGradient,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 64,
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: labelColor,
                      fontFamily: flutterLensFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
