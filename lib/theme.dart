
import 'package:flutter/material.dart';

class TerminalColors {
  static const bg         = Color(0xFF0B0E14);
  static const surface    = Color(0xFF10151C);
  static const surfaceHi  = Color(0xFF161B22);
  static const border     = Color(0xFF1F262E);
  static const borderHi   = Color(0xFF2D333B);

  static const text       = Color(0xFFC9D1D9);
  static const textDim    = Color(0xFF7D8590);
  static const textBright = Color(0xFFF0F6FC);

  static const primary    = Color(0xFF4EC9B0); // C++ teal
  static const amber      = Color(0xFFFFB454);
  static const pink       = Color(0xFFFF7EB6);
  static const blue       = Color(0xFF79C0FF);
  static const red        = Color(0xFFFF5C5C);
  static const green      = Color(0xFF3FB950);
}

ThemeData buildTerminalTheme() {
  // Use the main ThemeData constructor so we can pass fontFamily.
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'monospace',
  );

  return base.copyWith(
    scaffoldBackgroundColor: TerminalColors.bg,
    // (remove the `fontFamily: 'monospace',` line that used to be here)
    colorScheme: const ColorScheme.dark(
      primary: TerminalColors.primary,
      onPrimary: TerminalColors.bg,
      secondary: TerminalColors.amber,
      surface: TerminalColors.surface,
      onSurface: TerminalColors.text,
      error: TerminalColors.red,
    ),
    textTheme: base.textTheme
        .apply(
          fontFamily: 'monospace',
          bodyColor: TerminalColors.text,
          displayColor: TerminalColors.textBright,
        )
        .copyWith(
          bodyMedium: const TextStyle(
            fontFamily: 'monospace',
            color: TerminalColors.text,
            fontSize: 13,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TerminalColors.bg,
      foregroundColor: TerminalColors.textBright,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'monospace',
        color: TerminalColors.textBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: TerminalColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TerminalColors.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: const TextStyle(
        color: TerminalColors.textDim,
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      floatingLabelStyle: const TextStyle(
        color: TerminalColors.primary,
        fontFamily: 'monospace',
        fontSize: 12,
      ),
      hintStyle: const TextStyle(
        color: TerminalColors.textDim,
        fontFamily: 'monospace',
      ),
      border: _border(TerminalColors.border),
      enabledBorder: _border(TerminalColors.border),
      focusedBorder: _border(TerminalColors.primary, width: 1.4),
      errorBorder: _border(TerminalColors.red),
      focusedErrorBorder: _border(TerminalColors.red, width: 1.4),
    ),
  );
}

OutlineInputBorder _border(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: BorderSide(color: color, width: width),
    );

/// A little blinking block cursor, like a real terminal.
class BlinkingCursor extends StatefulWidget {
  final Color color;
  final double width;
  final double height;
  const BlinkingCursor({
    super.key,
    this.color = TerminalColors.primary,
    this.width = 8,
    this.height = 14,
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.color,
      ),
    );
  }
}
