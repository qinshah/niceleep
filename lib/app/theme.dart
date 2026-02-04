import 'package:flutter/material.dart';
import 'package:niceleep/app/services/config_service.dart';

enum ThemeColor {
  red(Color(0xFFB3261E), '樱桃红'),
  purple(Color(0xFF6750A4), '薰衣紫'),
  violet(Color(0xFF4F378B), '丁香紫'),
  gray(Color(0xFF52525A), '静谧灰'),
  blue(Color(0xFF006493), '海洋蓝'),
  green(Color(0xFF006D3C), '翡翠绿'),
  yellow(Color(0xFF7D5700), '琥珀黄'),
  pink(Color(0xFF7D5260), '珊瑚粉');

  final Color value;
  final String name;
  const ThemeColor(this.value, this.name);
}

class AppTheme {
  // 默认主题色
  static final defaultSeedColor = ThemeColor.red.value;
  // 亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        primary: const Color(0xFF6750A4),
        onPrimary: Colors.white,
        secondary: const Color(0xFF625B71),
        onSecondary: Colors.white,
        tertiary: const Color(0xFF7D5260),
        surface: const Color(0xFFFFFBFE),
        onSurface: const Color(0xFF1C1B1F),
        surfaceContainerHighest: const Color(0xFFE7E0EC),
        onSurfaceVariant: const Color(0xFF49454F),
        outline: const Color(0xFF79747E),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBFE),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFE7E0EC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE7E0EC),
      ),
    );
  }

  // 暗色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD0BCFF),
        primary: const Color(0xFFD0BCFF),
        onPrimary: const Color(0xFF381E72),
        secondary: const Color(0xFFCCC2DC),
        onSecondary: const Color(0xFF332D41),
        tertiary: const Color(0xFFEFB8C8),
        onTertiary: const Color(0xFF492532),
        surface: const Color(0xFF1C1B1F),
        onSurface: const Color(0xFFE6E1E5),
        surfaceContainerHighest: const Color(0xFF49454F),
        onSurfaceVariant: const Color(0xFFCAC4D0),
        outline: const Color(0xFF938F99),
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1B1F),
      cardTheme: const CardThemeData(
        color: Color(0xFF2B2930),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF49454F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF2B2930),
        indicatorColor: Color(0xFF49454F),
      ),
    );
  }

  /// 从存储获取主题模式
  static Future<ThemeMode> getThemeMode() async {
    return await ConfigService.getThemeMode();
  }

  /// 设置主题模式
  static Future<void> setThemeMode(ThemeMode mode) async {
    await ConfigService.setThemeMode(mode);
  }

  /// 获取保存的主题色
  static Future<Color> getSeedColor() async {
    return await ConfigService.getSeedColor();
  }

  /// 设置主题色
  static Future<void> setSeedColor(Color color) async {
    await ConfigService.setSeedColor(color);
  }

  /// 是否使用动态颜色
  static Future<bool> getUseDynamicColor() async {
    return await ConfigService.getUseDynamicColor();
  }

  /// 设置动态颜色
  static Future<void> setUseDynamicColor(bool use) async {
    await ConfigService.setUseDynamicColor(use);
  }

  /// 是否使用纯黑背景
  static Future<bool> getUseBlackBackground() async {
    return await ConfigService.getUseBlackBackground();
  }

  /// 设置纯黑背景
  static Future<void> setUseBlackBackground(bool use) async {
    await ConfigService.setUseBlackBackground(use);
  }
}