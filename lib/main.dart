import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:niceleep/app/app_view.dart';
import 'package:niceleep/app/services/config_service.dart';
import 'package:niceleep/app/services/sound_service.dart';
import 'package:niceleep/app/state_mgmt/sound_manager.dart';
import 'package:os_type/os_type.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 如果需要在鸿蒙上判断是否为PC/Mobile，需要先await OS.initHarmonyDeviceType()
  if (OS.isHarmony) await OS.initHarmonyDeviceType();

  // 初始化配置服务
  await ConfigService.init();
  // 初始化音频服务
  await SoundService.instance.initialize();
  // 初始化media_kit
  MediaKit.ensureInitialized();
  // 初始化声音管理器
  await SoundManager.i.init();

  runApp(const AppView());
}
