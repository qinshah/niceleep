import 'package:flutter_test/flutter_test.dart';
import 'package:niceleep/app/services/config_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('Hive Storage Tests', () {
    setUpAll(() async {
      // 初始化配置服务
      await ConfigService.init();
    });

    tearDownAll(() async {
      // 关闭配置服务
      await ConfigService.close();
    });

    test('should save and load theme mode', () async {
      // 保存主题模式
      await ConfigService.setThemeMode(ThemeMode.dark);
      
      // 读取主题模式
      final themeMode = await ConfigService.getThemeMode();
      
      expect(themeMode, ThemeMode.dark);
    });

    test('should save and load seed color', () async {
      const testColor = Color(0xFF6750A4);
      
      // 保存主题色
      await ConfigService.setSeedColor(testColor);
      
      // 读取主题色
      final seedColor = await ConfigService.getSeedColor();
      
      expect(seedColor, testColor);
    });

    test('should save and load max sound count', () async {
      const testCount = 15;
      
      // 保存最大声音数量
      await ConfigService.setMaxSoundCount(testCount);
      
      // 读取最大声音数量
      final maxSoundCount = await ConfigService.getMaxSoundCount();
      
      expect(maxSoundCount, testCount);
    });

    test('should save and load boolean values', () async {
      // 测试动态颜色设置
      await ConfigService.setUseDynamicColor(true);
      expect(await ConfigService.getUseDynamicColor(), true);
      
      // 测试纯黑背景设置
      await ConfigService.setUseBlackBackground(true);
      expect(await ConfigService.getUseBlackBackground(), true);
    });
  });
}