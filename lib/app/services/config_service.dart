import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:niceleep/app/data_model/app_config.dart';
import 'package:flutter/material.dart';

class ConfigService {
  static const String _boxName = 'app_config';
  static Box<AppConfig>? _configBox;
  static AppConfig? _currentConfig;

  // 初始化 Hive 和配置
  static Future<void> init() async {
    // 初始化 Hive
    await Hive.initFlutter();
    
    // 注册适配器
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppConfigAdapter());
    }
    
    // 打开配置盒子
    _configBox = await Hive.openBox<AppConfig>(_boxName);
    
    // 加载或创建默认配置
    _currentConfig = _configBox!.get('config');
    if (_currentConfig == null) {
      _currentConfig = AppConfig();
      await _saveConfig();
    }
  }

  // 保存配置
  static Future<void> _saveConfig() async {
    if (_configBox != null && _currentConfig != null) {
      await _configBox!.put('config', _currentConfig!);
    }
  }

  // 获取当前配置
  static AppConfig get currentConfig {
    if (_currentConfig == null) {
      throw Exception('ConfigService not initialized. Call init() first.');
    }
    return _currentConfig!;
  }

  // 主题模式相关操作
  static Future<ThemeMode> getThemeMode() async {
    return currentConfig.themeModeEnum;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    currentConfig.themeModeEnum = mode;
    await _saveConfig();
  }

  // 主题色相关操作
  static Future<Color> getSeedColor() async {
    return currentConfig.seedColor;
  }

  static Future<void> setSeedColor(Color color) async {
    currentConfig.seedColor = color;
    await _saveConfig();
  }

  // 动态颜色相关操作
  static Future<bool> getUseDynamicColor() async {
    return currentConfig.useDynamicColor;
  }

  static Future<void> setUseDynamicColor(bool use) async {
    currentConfig.useDynamicColor = use;
    await _saveConfig();
  }

  // 纯黑背景相关操作
  static Future<bool> getUseBlackBackground() async {
    return currentConfig.useBlackBackground;
  }

  static Future<void> setUseBlackBackground(bool use) async {
    currentConfig.useBlackBackground = use;
    await _saveConfig();
  }

  // 最大声音数量相关操作
  static Future<int> getMaxSoundCount() async {
    return currentConfig.maxSoundCount;
  }

  static Future<void> setMaxSoundCount(int count) async {
    currentConfig.maxSoundCount = count;
    await _saveConfig();
  }

  // 关闭 Hive
  static Future<void> close() async {
    await _configBox?.close();
  }
}