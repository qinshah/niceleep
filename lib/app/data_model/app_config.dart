import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';

part 'app_config.g.dart';

@HiveType(typeId: 0)
class AppConfig extends HiveObject {
  @HiveField(0)
  late String themeMode;

  @HiveField(1)
  late int seedColorValue;

  @HiveField(2)
  late bool useDynamicColor;

  @HiveField(3)
  late bool useBlackBackground;

  @HiveField(4)
  late int maxSoundCount;

  AppConfig({
    this.themeMode = 'system',
    this.seedColorValue = 0xFFB3261E, // 默认红色
    this.useDynamicColor = false,
    this.useBlackBackground = false,
    this.maxSoundCount = 10,
  });

  // 转换主题模式字符串为ThemeMode枚举
  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  set themeModeEnum(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        themeMode = 'light';
        break;
      case ThemeMode.dark:
        themeMode = 'dark';
        break;
      case ThemeMode.system:
        themeMode = 'system';
        break;
    }
  }

  // 获取主题色
  Color get seedColor => Color(seedColorValue);

  // 设置主题色
  set seedColor(Color color) => seedColorValue = color.value;
}