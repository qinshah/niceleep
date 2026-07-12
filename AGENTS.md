# 响入睡 (NiceSleep) - 项目架构文档

## 一、项目概述

**响入睡** 是一款基于 Flutter 的多平台白噪音/助眠声音应用，支持 Android、iOS、macOS、Windows、Linux 和鸿蒙系统。应用提供丰富的自然声音、白噪音等助眠音效，支持多音叠加播放、定时关闭、主题定制等功能。

### 核心特性

| 特性 | 描述 |
|------|------|
| 多音叠加 | 支持同时播放多个音频（默认最多10个，可配置） |
| 定时关闭 | 支持设置定时自动停止播放或退出应用 |
| 主题定制 | 支持浅色/深色/跟随系统模式，多种主题色可选 |
| 灵动岛支持 | 集成系统媒体通知，支持灵动岛显示 |
| 多平台适配 | 全面支持鸿蒙系统及主流桌面/移动平台 |

---

## 二、目录结构

```
lib/
├── app/                      # 核心应用层
│   ├── data_model/           # 数据模型
│   │   ├── app_config.dart   # 应用配置模型(Hive)
│   │   ├── app_config.g.dart # Hive适配器(自动生成)
│   │   ├── playing_sound.dart# 正在播放的声音模型
│   │   ├── sound_asset.dart  # 声音资源模型
│   │   └── sound_category.dart# 声音分类模型
│   ├── services/             # 服务层
│   │   ├── config_service.dart# 配置服务(Hive)
│   │   └── sound_service.dart # 声音资源服务
│   ├── state_mgmt/           # 状态管理
│   │   └── play_manager.dart # 播放管理器
│   ├── app_view.dart         # 应用主视图
│   ├── constant.dart         # 常量定义
│   └── theme.dart            # 主题配置
├── home/                     # 首页模块
│   └── home_page.dart        # 首页视图
├── timed_off/                # 定时关闭模块
│   ├── sleep_timer.dart      # 定时器逻辑
│   └── timed_off_page_view.dart # 定时页面
├── settings/                 # 设置模块
│   ├── state_mgmt/
│   │   └── theme_cntlr.dart  # 主题控制器
│   ├── settings_page_view.dart # 设置页面
│   └── theme_page_view.dart  # 主题设置页面
├── hive_registrar.g.dart     # Hive适配器注册(自动生成)
└── main.dart                 # 应用入口

.vscode/
├── env_gen.dart              # 环境变量生成脚本
└── env.json                  # 环境变量配置(自动生成)
```

---

## 三、核心架构

### 3.1 应用启动流程

```
main.dart
    │
    ├── ConfigService.init()        # 初始化 Hive 配置存储
    ├── SoundService.instance.initialize() # 加载 sounds.json 声音清单
    ├── MediaKit.ensureInitialized() # 初始化 media_kit 音频引擎
    ├── PlayManager.i.init()        # 初始化播放管理器(含 audio_service)
    └── runApp(AppView())           # 启动应用
```

### 3.2 状态管理架构

应用采用 **Provider** 作为状态管理方案，通过 `MultiProvider` 提供全局状态：

| Provider | 职责 | 作用域 |
|----------|------|--------|
| `PlayManager.i` | 管理音频播放、音量、播放列表 | 全局 |
| `ThemeCntlr.i` | 管理主题模式、主题色、深色模式 | 全局 |

### 3.3 音频播放架构

```
用户点击声音卡片
    │
    ├── PlayManager.playNew(SoundAsset)
    │       │
    │       ├── 创建 media_kit Player 实例
    │       ├── 将音频资源写入临时文件(兼容处理)
    │       ├── 打开媒体并设置循环播放
    │       └── 更新播放状态通知UI
    │
    └── AudioService(系统通知)
            ├── 更新灵动岛/通知栏显示
            └── 响应系统播放/暂停控制
```

---

## 四、关键模块详解

### 4.1 数据模型

#### SoundAsset
定义单个声音资源的属性：

```dart
SoundAsset {
  id: String              // 唯一标识(格式: category_id)
  name: String            // 声音名称
  path: String            // 资源路径
  category: String        // 所属分类名称
  icon: IconData          // 分类图标
  nameEn: String?         // 英文名称
  nameZhTW: String?       // 繁体名称
  order: int?             // 排序号
  isSeamless: bool?       // 是否无缝循环
  loopStart: double?      // 循环起始位置
  loopEnd: double?        // 循环结束位置
}
```

#### SoundCategory
定义声音分类：

```dart
SoundCategory {
  id: String              // 分类标识(如: rain, nature)
  name: String            // 分类名称
  nameEn: String          // 英文名称
  nameZhTW: String        // 繁体名称
  order: int              // 排序号
  icon: IconData          // 分类图标
}
```

#### PlayingSound
运行时播放状态：

```dart
PlayingSound {
  asset: SoundAsset       // 声音资源
  player: Player          // media_kit 播放器实例
}
```

#### AppConfig (Hive 模型)
应用配置的持久化模型，使用 Hive 存储：

```dart
@HiveType(typeId: 0)
class AppConfig extends HiveObject {
  @HiveField(0) String themeMode;           // 'light' | 'dark' | 'system'
  @HiveField(1) int seedColorValue;         // 主题色整数值
  @HiveField(2) bool useDynamicColor;       // 动态颜色开关
  @HiveField(3) bool useBlackBackground;    // 纯黑背景开关
  @HiveField(4) int maxSoundCount;          // 最大播放数(默认10)
}
```

### 4.2 服务层

#### SoundService

**职责**：从 `assets/sounds.json` 加载声音清单，提供声音查询和分类功能。

**核心方法**：

| 方法 | 功能 |
|------|------|
| `initialize()` | 加载 JSON 并解析声音/分类数据 |
| `getSoundsByCategory()` | 按分类获取声音列表 |
| `getSoundById()` | 按 ID 获取单个声音 |
| `searchSounds()` | 搜索声音(支持名称/英文/分类) |
| `getSoundsGroupedByCategory()` | 获取按分类分组的声音 |

#### ConfigService

**职责**：基于 Hive 存储管理应用配置，提供配置读写接口。

**存储配置**：

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| themeMode | ThemeMode | system | 主题模式 |
| seedColor | Color | 樱桃红(#B3261E) | 主题色 |
| useDynamicColor | bool | false | 动态颜色 |
| useBlackBackground | bool | false | 纯黑背景 |
| maxSoundCount | int | 10 | 最大同时播放数 |

#### PlayManager

**职责**：管理音频播放生命周期，集成 media_kit 和 audio_service。

**核心功能**：

| 功能 | 方法 |
|------|------|
| 播放新声音 | `playNew(SoundAsset)` |
| 停止单个声音 | `stopByAsset(SoundAsset)` |
| 停止所有声音 | `stopAll()` |
| 暂停/恢复所有 | `pauseAll() / resumeAll()` |
| 调节音量 | `setVolume() / setAllVolume()` |
| 系统通知响应 | `play() / pause() / stop()` |

#### SleepTimer

**职责**：定时关闭功能，支持倒计时和回调操作。

```dart
SleepTimer.set({
  duration: Duration,     // 定时时长
  isExit: bool            // true=退出应用, false=停止播放
});
```

### 4.3 页面模块

#### HomePage

首页包含：
- **分类过滤**：横向滚动的 FilterChip 分类选择
- **声音网格**：按分类分组展示或平铺展示声音卡片
- **播放列表入口**：悬浮按钮打开底部播放列表
- **SoundCard**：声音卡片组件，显示播放状态和快捷操作

#### TimedOffPageView

定时关闭页面：
- **时长设置**：滑块和输入框两种方式
- **剩余时间显示**：定时运行时显示倒计时
- **结束行为选择**：停止播放 / 退出应用

#### SettingsPageView

设置页面：
- **主题设置**：跳转主题配置页面
- **统一音量**：调整所有播放声音的音量
- **最大音频数**：配置同时播放的声音上限
- **隐私政策**：仅商店版显示(通过 `isStoreVersion` 环境变量控制)

#### ThemePageView

主题配置页面：
- **外观模式**：浅色/深色/跟随系统
- **高对比度**：深色模式下使用纯黑背景
- **调色板**：8种主题色可选

---

## 五、技术栈

### 5.1 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | ^3.10.0 | 框架核心 |
| media_kit | git | 跨平台音频播放 |
| audio_service | git | 系统媒体通知/灵动岛 |
| audio_session | git | 音频会话管理 |
| hive_ce | ^2.16.0 | 本地数据存储(纯Dart实现) |
| hive_ce_flutter | ^2.3.3 | Hive Flutter适配 |
| hive_ce_generator | ^1.11.1 | Hive适配器生成器 |
| provider | ^6.1.5 | 状态管理 |
| package_info_plus | git | 应用信息 |
| url_launcher | git | 链接跳转 |
| os_type | ^0.2.2 | 系统类型检测 |
| build_runner | ^2.4.11 | 代码生成工具 |

### 5.2 鸿蒙系统适配策略

项目使用 **git 依赖覆盖** 策略来适配鸿蒙系统：

| 包名 | 原版本 | 鸿蒙适配版本来源 |
|------|--------|------------------|
| audio_service | pub.dev | gitcode.com/openharmony-sig |
| audio_session | pub.dev | gitcode.com/openharmony-sig |
| package_info_plus | pub.dev | gitcode.com/openharmony-sig |
| path_provider | pub.dev | gitcode.com/openharmony-tpc |
| url_launcher | pub.dev | gitcode.com/openharmony-tpc |

**原因**：官方 pub.dev 上的包大多不支持鸿蒙系统，需要使用社区适配的 git 仓库版本。

### 5.3 代码生成

项目使用 `build_runner` 生成以下代码：

| 文件 | 生成命令 | 用途 |
|------|----------|------|
| `app_config.g.dart` | `build_runner build` | Hive 序列化适配器 |
| `hive_registrar.g.dart` | `build_runner build` | Hive 适配器注册 |

---

## 六、资源结构

音频资源位于 `assets/audio/`，按分类组织：

```
assets/audio/
├── animals/        # 动物声音(16种)
├── nature/         # 自然声音(14种)
├── noise/          # 白噪音(6种)
├── places/         # 场所声音(16种)
├── rain/           # 雨声(15种)
├── things/         # 物品声音(20种)
├── transport/      # 交通工具(6种)
└── urban/          # 城市声音(6种)
```

声音清单定义在 `assets/sounds.json`，包含：
- `categories`: 分类定义数组
- `sounds`: 声音定义数组

---

## 七、设计规范

### 7.1 主题系统

应用使用 Material 3 设计规范：
- **亮色主题**：seedColor 生成的暖色调配色
- **暗色主题**：深色背景 + 高对比度文字
- **高对比度模式**：纯黑背景，省电且护眼

### 7.2 主题色选项

| 颜色 | 名称 | 色值 |
|------|------|------|
| 樱桃红 | red | #B3261E |
| 薰衣紫 | purple | #6750A4 |
| 丁香紫 | violet | #4F378B |
| 静谧灰 | gray | #52525A |
| 海洋蓝 | blue | #006493 |
| 翡翠绿 | green | #006D3C |
| 琥珀黄 | yellow | #7D5700 |
| 珊瑚粉 | pink | #7D5260 |

---

## 八、Agent Guidelines

### 8.1 编码规范

#### 代码风格
- 遵循 `flutter_lints` 规则（`analysis_options.yaml`）
- 使用 2 空格缩进
- 文件名使用小写蛇形命名（如 `sound_service.dart`）
- 类名使用大驼峰命名（如 `SoundService`）
- 常量使用全大写蛇形命名（如 `MAX_SOUND_COUNT`）

#### 状态管理模式
- **全局状态**：使用 Provider + Singleton 模式（参考 `PlayManager`、`ThemeCntlr`）
- **局部状态**：使用 `StatefulWidget` + `setState`
- **响应式更新**：使用 `context.watch()`、`context.select()` 获取状态

#### 服务层模式
- 使用 **Singleton** 模式（`static final instance = _()`）
- 在 `main.dart` 中初始化所有服务
- 服务之间通过直接调用方式交互（无依赖注入框架）

### 8.2 如何添加新声音

1. **添加音频文件**：将 `.ogg` 文件放入 `assets/audio/{category}/`
2. **更新 sounds.json**：在对应分类下添加声音定义
3. **验证**：运行 `flutter pub get` 和 `flutter run`

**sounds.json 格式示例**：
```json
{
  "categories": [...],
  "sounds": [
    {
      "id": "my_sound",
      "name": "我的声音",
      "nameEn": "My Sound",
      "nameZhTW": "我的聲音",
      "category": "rain",
      "path": "assets/audio/rain/my_sound.ogg",
      "order": 100,
      "isSeamless": true
    }
  ]
}
```

### 8.3 如何添加新分类

1. **创建文件夹**：在 `assets/audio/` 下创建新分类文件夹
2. **更新 sounds.json**：在 `categories` 数组中添加新分类
3. **更新图标映射**：在 `SoundCategory._getCategoryIcon()` 中添加分类图标

**categories.json 格式示例**：
```json
{
  "id": "my_category",
  "name": "我的分类",
  "nameEn": "My Category",
  "nameZhTW": "我的分類",
  "order": 99
}
```

### 8.4 如何添加新页面

1. **创建页面文件**：在对应模块目录下创建 `xxx_page_view.dart`
2. **添加导航**：在 `AppView._pages` 列表中添加页面（底部导航）
3. **更新底部导航**：在 `NavigationBar.destinations` 中添加新目的地

### 8.5 如何添加新配置项

1. **更新 AppConfig**：在 `app_config.dart` 中添加新字段和 `@HiveField` 注解
2. **重新生成适配器**：运行 `dart run build_runner build`
3. **更新 ConfigService**：添加 getter/setter 方法
4. **更新 UI**：在设置页面中添加配置控件

### 8.6 常见陷阱

#### media_kit Asset 加载问题
- **问题**：部分平台不支持直接加载 `asset:///` 路径
- **解决方案**：参考 `PlayManager.playNew()` 中的双重加载策略
- **代码模式**：先尝试直接加载，失败时写入临时文件再加载

```dart
Playable? media;
try {
  media = Media('asset:///$assetPath');
} catch (e) {
  // 写入临时文件
  final tempFile = File('${Directory.systemTemp.path}/$fileName');
  final byteData = await rootBundle.load(assetPath);
  await tempFile.writeAsBytes(byteData.buffer.asUint8List());
  media = Media(tempFile.path);
}
```

#### Hive 适配器注册
- **问题**：修改 `AppConfig` 后忘记重新生成适配器
- **解决方案**：每次修改模型后运行 `dart run build_runner build`

#### 资源释放
- **问题**：`Player` 实例未正确释放导致内存泄漏
- **解决方案**：在 `stopByAsset()` 和 `stopAll()` 中调用 `player.dispose()`

#### 环境变量
- **问题**：商店版功能（如隐私政策）未正确显示
- **解决方案**：通过 `dart run .vscode/env_gen.dart` 生成 `env.json`

---

## 九、开发注意事项

### 9.1 音频加载兼容处理

由于部分平台对 asset 路径支持有限，`PlayManager` 采用双重加载策略：

1. 优先尝试直接加载 `asset:///path`
2. 失败时将 asset 写入临时文件，再加载临时文件路径

### 9.2 最大播放数限制

为避免性能问题，应用限制同时播放的音频数量：
- 默认值：10
- 可配置范围：5-20
- 超出限制时显示 SnackBar 提示

### 9.3 生命周期管理

- `PlayManager` 在 `AppView.dispose()` 时调用 `dispose()` 释放资源
- `SleepTimer` 使用 `Timer.periodic`，需在页面销毁时取消
- `TextEditingController` 需在 `State.dispose()` 时释放

---

## 十、构建命令

```bash
# 安装依赖
flutter pub get

# 生成 Hive 适配器
dart run build_runner build

# 生成环境变量(商店版)
dart run .vscode/env_gen.dart

# 运行(开发模式)
flutter run

# 构建 APK
flutter build apk

# 构建 iOS
flutter build ios

# 构建鸿蒙
flutter build ohos

# 构建 Web
flutter build web
```

---

## 十一、扩展建议

### 11.1 潜在功能扩展

- [ ] 用户自定义音频上传
- [ ] 收藏/喜欢声音
- [ ] 音效混合预设
- [ ] 睡眠统计
- [ ] 多语言支持

### 11.2 代码优化方向

- [ ] 添加单元测试
- [ ] 优化音频加载性能
- [ ] 实现音频淡入淡出
- [ ] 支持蓝牙设备控制