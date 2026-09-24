import 'package:flutter/material.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B5BDB),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
