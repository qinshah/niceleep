import 'package:flutter/material.dart';
import 'package:niceleep/app/app_view.dart';
import 'package:niceleep/app/services/config_service.dart';
import 'package:niceleep/app/state_mgmt/sound_manager.dart';
import 'package:os_type/os_type.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 如果需要在鸿蒙上判断是否为PC/Mobile，需要先await OS.initHarmonyDeviceType()
  if (OS.isHarmony) await OS.initHarmonyDeviceType();
  
  // 初始化配置服务
  await ConfigService.init();
  
  // 初始化声音管理器
  await SoundManager.i.init();
  
  runApp(const AppView());
}