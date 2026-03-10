import 'package:flutter/material.dart';
import 'package:flutter_debug_tools/src/state/debug_tools_state.dart';
import 'package:flutter_debug_tools/src/utils/device_info_manager.dart';
import 'package:flutter_debug_tools/src/view/debug_tools_panel_styles.dart';

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
    final data = <String, String>{
      for (final entry in state.value.deviceData.entries) entry.key: '${entry.value}'.trim(),
    };

    final brand = _value(data, ['Brand', 'Name']);
    final model = _value(data, ['Model', 'Localized Model']);
    final device = _value(data, ['Device', 'Model', 'Localized Model']);
    final release = _value(data, ['Release Version', 'System Version']);
    final sdk = _value(data, ['SDK Version']);
    final systemName = _value(data, ['System Name']);
    final buildFingerprint = _value(data, ['Build Fingerprint']);
    final displayIdentifier = _value(data, ['Display']);
    final vendorIdentifier = _value(data, ['Identifier For Vendor']);
    final securityPatch = _value(data, ['Security Patch Version']);

    final consumedKeys = <String>{
      'Brand',
      'Name',
      'Model',
      'Localized Model',
      'Device',
      'Release Version',
      'System Version',
      'SDK Version',
      'System Name',
      'Display',
      'Identifier For Vendor',
      'Build Fingerprint',
      'Security Patch Version',
      'Board',
      'Product',
    };

    final remainingEntries = state.value.deviceData.entries
        .where((entry) => !consumedKeys.contains(entry.key))
        .map((entry) => _SpecTileData(label: entry.key, value: '${entry.value}', isMono: true))
        .toList();

    return Scaffold(
      backgroundColor: DebugToolsPanelStyles.sheetFill,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    'Device Details',
                    style: _DeviceTextStyles.screenTitle,
                  ),
                ),
                const Spacer(),
                _HeaderButton(
                  icon: Icons.clear_rounded,
                  onTap: onTap,
                ),
                const SizedBox(width: 16),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ListView(
                  clipBehavior: Clip.none,
                  children: [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: DebugToolsPanelStyles.accentGradient,
                                  ),
                                  padding: const EdgeInsets.all(1.3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D0D0F),
                                      borderRadius: BorderRadius.circular(14.7),
                                    ),
                                    child: const Icon(Icons.phone_android_rounded, color: Colors.white70, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (brand.isNotEmpty || model.isNotEmpty)
                                        Text(
                                          '${brand.toUpperCase()}${brand.isNotEmpty && model.isNotEmpty ? ' · ' : ''}${model.toUpperCase()}',
                                          style: _DeviceTextStyles.caption.copyWith(
                                              color: DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.42)),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        device.isEmpty ? 'Unknown Device' : device,
                                        style: _DeviceTextStyles.value
                                            .copyWith(color: DebugToolsPanelStyles.textPrimary.withValues(alpha: 0.92)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (buildFingerprint.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BUILD FINGERPRINT',
                                    style:
                                        _DeviceTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.40)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    buildFingerprint,
                                    style: _DeviceTextStyles.valueSmall.copyWith(
                                      color: Colors.white.withValues(alpha: 0.78),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SpecSection(
                      title: 'DISPLAY',
                      icon: Icons.desktop_windows_rounded,
                      accentColor: const Color(0xFF4ADE80),
                      items: [
                        _SpecTileData(
                          label: 'Resolution',
                          value: '${screenSize.width.toStringAsFixed(0)} x ${screenSize.height.toStringAsFixed(0)}',
                          footnote: 'PIXELS',
                        ),
                        _SpecTileData(
                          label: 'Density',
                          value: '${screenDensity.toStringAsFixed(1)}x',
                          footnote: _densityBucket(screenDensity),
                        ),
                        if (displayIdentifier.isNotEmpty)
                          _SpecTileData(
                            label: 'Display Identifier',
                            value: displayIdentifier,
                            isMono: true,
                            fullWidth: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SpecSection(
                      title: 'SYSTEM',
                      icon: Icons.settings_input_component_rounded,
                      accentColor: const Color(0xFFF7A250),
                      items: [
                        if (sdk.isNotEmpty)
                          _SpecTileData(
                            label: 'SDK Version',
                            value: sdk,
                            footnote: _androidCodeName(sdk),
                            accent: true,
                          ),
                        if (release.isNotEmpty)
                          _SpecTileData(
                            label: 'Release',
                            value: release,
                            footnote: systemName.isNotEmpty ? '$systemName $release' : '',
                            accent: true,
                          ),
                        if (securityPatch.isNotEmpty)
                          _SpecTileData(
                            label: 'Security Patch',
                            value: securityPatch,
                            footnote: 'PATCH APPLIED',
                            fullWidth: true,
                          ),
                        if (vendorIdentifier.isNotEmpty)
                          _SpecTileData(
                            label: 'Identifier For Vendor',
                            value: vendorIdentifier,
                            isMono: true,
                            fullWidth: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SpecSection(
                      title: 'HARDWARE',
                      icon: Icons.memory_rounded,
                      accentColor: const Color(0xFFE24A79),
                      items: [
                        _SpecTileData(label: 'Board', value: _value(data, ['Board'])),
                        _SpecTileData(label: 'Brand', value: brand),
                        _SpecTileData(label: 'Model', value: model),
                        _SpecTileData(label: 'Product', value: _value(data, ['Product'])),
                        _SpecTileData(label: 'Device', value: _value(data, ['Device'])),
                      ].where((item) => item.value.isNotEmpty).toList(),
                    ),
                    if (remainingEntries.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SpecSection(
                        title: 'OTHER',
                        icon: Icons.more_horiz_rounded,
                        accentColor: const Color(0xFF9EA3AD),
                        items: remainingEntries,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _value(Map<String, String> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _densityBucket(double density) {
    if (density >= 4.0) return 'XXXHDPI';
    if (density >= 3.0) return 'XXHDPI';
    if (density >= 2.0) return 'XHDPI';
    if (density >= 1.5) return 'HDPI';
    if (density >= 1.0) return 'MDPI';
    return 'LDPI';
  }

  String _androidCodeName(String sdkText) {
    final sdk = int.tryParse(sdkText);
    if (sdk == null) return '';

    if (sdk >= 35) return 'ANDROID 15';
    if (sdk == 34) return 'ANDROID 14';
    if (sdk == 33) return 'ANDROID 13';
    if (sdk == 32 || sdk == 31) return 'ANDROID S';
    if (sdk == 30) return 'ANDROID R';
    if (sdk == 29) return 'ANDROID Q';
    return 'ANDROID';
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

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
          child: child,
        ),
      ),
    );
  }
}

class _SpecSection extends StatelessWidget {
  const _SpecSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_SpecTileData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return _GlassCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentColor.withValues(alpha: 0.22), accentColor.withValues(alpha: 0.08)],
                    ),
                    border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: _DeviceTextStyles.sectionTitle.copyWith(color: accentColor.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: item.fullWidth ? constraints.maxWidth : width,
                        child: _SpecTile(item: item),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecTileData {
  const _SpecTileData({
    required this.label,
    required this.value,
    this.footnote = '',
    this.isMono = false,
    this.fullWidth = false,
    this.accent = false,
  });

  final String label;
  final String value;
  final String footnote;
  final bool isMono;
  final bool fullWidth;
  final bool accent;
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.item});

  final _SpecTileData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: item.accent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x33F7A250), Color(0x22E24A79), Color(0x115A3386)],
              )
            : null,
        color: item.accent ? null : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: item.accent ? const Color(0x66E24A79) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label.toUpperCase(),
            style: _DeviceTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.36)),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: _DeviceTextStyles.value.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          if (item.footnote.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              item.footnote,
              style: _DeviceTextStyles.footnote.copyWith(
                color: item.accent ? const Color(0xCCF7A250) : Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: _DeviceTextStyles.pill.copyWith(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _DeviceTextStyles {
  static const TextStyle screenTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: DebugToolsPanelStyles.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.9,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle value = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle valueSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle pill = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
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
