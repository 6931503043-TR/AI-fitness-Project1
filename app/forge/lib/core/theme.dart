import 'package:flutter/material.dart';

/// สีที่พอร์ตมาจากตัวแปร CSS ในไฟล์ gym-app.html
class ForgeColors {
  static const bg = Color(0xFF14130F);
  static const surface = Color(0xFF1E1C17);
  static const surface2 = Color(0xFF26241D);
  static const border = Color(0x1AF5F3EE); // ~10%
  static const borderStrong = Color(0x2EF5F3EE); // ~18%
  static const text = Color(0xFFF5F3EE);
  static const textSecondary = Color(0xFFA7A296);
  static const textMuted = Color(0xFF6E6A5F);
  static const accent = Color(0xFFFF5A1F);
  static const onAccent = Color(0xFF1B0A03);
  static const accentBg = Color(0x24FF5A1F); // ~14%
  static const recovery = Color(0xFF2BB3A3);
  static const danger = Color(0xFFE4574B);
}

/// การ์ดพื้นหลังเข้มมุมโค้งเหมือนใน HTML
const forgeCardDecoration = BoxDecoration(
  color: ForgeColors.surface,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  border: Border.fromBorderSide(BorderSide(color: ForgeColors.border)),
);

ThemeData buildForgeTheme() {
  const scheme = ColorScheme.dark(
    primary: ForgeColors.accent,
    onPrimary: ForgeColors.onAccent,
    secondary: ForgeColors.recovery,
    surface: ForgeColors.surface,
    onSurface: ForgeColors.text,
    error: ForgeColors.danger,
  );

  final baseText = ThemeData(brightness: Brightness.dark).textTheme.apply(
        bodyColor: ForgeColors.text,
        displayColor: ForgeColors.text,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ForgeColors.bg,
    textTheme: baseText,
    appBarTheme: const AppBarTheme(
      backgroundColor: ForgeColors.bg,
      foregroundColor: ForgeColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: ForgeColors.bg,
      indicatorColor: ForgeColors.accentBg,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ForgeColors.surface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: ForgeColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
