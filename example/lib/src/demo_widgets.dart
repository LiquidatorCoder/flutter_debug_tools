import 'dart:ui';

import 'package:flutter/material.dart';

import 'demo_theme.dart';

class DemoSurface extends StatelessWidget {
  const DemoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient ?? DemoTheme.surfaceGradient,
        border: Border.all(color: borderColor ?? DemoTheme.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.42),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onMenuTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onMenuTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HeaderIconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverToBoxAdapter(child: child),
          ),
        ],
      ),
    );
  }
}

class DemoSectionHeader extends StatelessWidget {
  const DemoSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
  });

  final String eyebrow;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class DemoPill extends StatelessWidget {
  const DemoPill({
    super.key,
    required this.label,
    this.color,
    this.active = false,
    this.onTap,
  });

  final String label;
  final Color? color;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill =
        active ? (color ?? DemoTheme.accent).withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.04);
    final Color stroke = active ? (color ?? DemoTheme.accent) : DemoTheme.border;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: fill,
            border: Border.all(color: stroke.withValues(alpha: active ? 0.9 : 1.0)),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

class DemoMetricTile extends StatelessWidget {
  const DemoMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.tint,
  });

  final String label;
  final String value;
  final String caption;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DemoSurface(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(caption, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ],
      ),
    );
  }
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DemoSurface(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.fromRGBO(247, 162, 80, 0.24),
              Color.fromRGBO(226, 74, 121, 0.16),
              Color.fromRGBO(90, 51, 134, 0.24),
            ],
          ),
          borderColor: DemoTheme.borderStrong,
          child: Row(
            children: <Widget>[
              const Icon(Icons.bolt_rounded, color: DemoTheme.warning),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(message, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _HeaderIconButton(icon: Icons.close_rounded, onTap: onDismiss),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoEmptyState extends StatelessWidget {
  const DemoEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DemoSurface(
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: DemoTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class DemoLoadingLines extends StatefulWidget {
  const DemoLoadingLines({super.key});

  @override
  State<DemoLoadingLines> createState() => _DemoLoadingLinesState();
}

class _DemoLoadingLinesState extends State<DemoLoadingLines> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double alpha = 0.12 + (_controller.value * 0.10);
        return DemoSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(4, (int index) {
              final double width = index == 0 ? 160 : 240 - (index * 28);
              return Padding(
                padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
                child: Container(
                  width: width,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: alpha),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: DemoTheme.border),
          ),
          child: Icon(icon, color: DemoTheme.textPrimary, size: 20),
        ),
      ),
    );
  }
}
