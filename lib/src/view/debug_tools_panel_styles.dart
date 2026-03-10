import 'package:flutter/material.dart';

class DebugToolsPanelStyles {
  static const Color sheetFill = Color.fromRGBO(18, 18, 20, 1);
  static const Color itemStart = Color.fromRGBO(38, 38, 42, 0.60);
  static const Color itemEnd = Color.fromRGBO(22, 22, 25, 0.60);
  static const Color itemActive = Color(0xFF0D0D0F);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color.fromRGBO(255, 255, 255, 0.45);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7A250), Color(0xFFE24A79), Color(0xFF5A3386)],
  );
}
