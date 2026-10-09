import 'package:flutter/material.dart';

abstract final class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  static bool get isDark => mode.value == ThemeMode.dark;

  static void setDark(bool enabled) {
    mode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggle() {
    setDark(!isDark);
  }
}
