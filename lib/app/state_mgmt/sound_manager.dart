import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart'
    hide AVAudioSessionCategory, AndroidAudioFocus;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:niceleep/app/constant.dart';
import 'package:niceleep/app/data_model/playing_sound.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/config_service.dart';

class SoundManager extends ChangeNotifier {
  SoundManager._();

  static final SoundManager i = SoundManager._();
  final _playingMap = <String, PlayingSound>{};
  List<PlayingSound> get playingSounds => _playingMap.values.toList();

  int _maxSoundCount = 10;

  int get maxSoundCount => _maxSoundCount;

  late final AudioHandler _audioHandler;

  // 初始化时从 Hive 加载最大声音数量
  Future<void> init() async {
    // 初始化音频服务和会话
    final audioSession = await AudioSession.instance;
    // 初始化 AudioHandler 用于系统媒体通知
    _audioHandler = await AudioService.init(
      builder: () => SoundPlayerHandler(audioSession),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
    notifyListeners();
    _maxSoundCount = await ConfigService.getMaxSoundCount();
    debugPrint('AudioService 初始化成功: $_audioHandler');
  }

  Future<bool> setMaxSoundCount(int count) async {
    try {
      await ConfigService.setMaxSoundCount(count);
      _maxSoundCount = count;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool countMaximum() => _playingMap.length >= _maxSoundCount;

  Future<void> play(SoundAsset asset) async {
    assert(!_playingMap.containsKey(asset.id), '此音频已在播放');
    assert(_playingMap.length < _maxSoundCount, '数量溢出');

    try {
      // 创建 media_kit Player
      final player = Player();

      // 设置为循环播放
      await player.setPlaylistMode(PlaylistMode.loop);
      // 设置默认音量 0.5
      await player.setVolume(50.0); // media_kit 音量范围是 0-100

      // 播放 asset 路径的音频
      // asset.path 格式为 'assets/sounds/nature/wind.ogg'
      final assetPath = asset.path;
      debugPrint('尝试播放 asset: $assetPath');

      // 先尝试直接使用 asset:// 路径
      try {
        final assetUri = 'asset:///$assetPath';
        debugPrint('尝试直接打开: $assetUri');
        await player.open(Media(assetUri));
        await player.play();
      } catch (e) {
        debugPrint('直接 asset:// 方式失败: $e');

        // 直接方式失败，尝试使用临时文件
        try {
          final tempDir = Directory.systemTemp;
          final fileName = assetPath
              .replaceAll('/', '_')
              .replaceAll('assets_', '');
          final tempFile = File('${tempDir.path}/$fileName');

          // 检查临时文件是否已存在
          if (await tempFile.exists()) {
            debugPrint('使用已存在的临时文件: ${tempFile.path}');
            await player.open(Media(tempFile.path));
            await player.play();
          } else {
            // 读取 asset 字节并写入临时文件
            debugPrint('临时文件不存在，创建新文件');
            final byteData = await rootBundle.load(assetPath);
            final bytes = byteData.buffer.asUint8List();
            await tempFile.writeAsBytes(bytes);
            debugPrint('临时文件路径: ${tempFile.path}');
            await player.open(Media(tempFile.path));
            await player.play();
          }
        } catch (e2) {
          debugPrint('临时文件方式也失败: $e2');
        }
      }

      _audioHandler.play();
      notifyListeners();
      _playingMap[asset.id] = PlayingSound(asset: asset, player: player);
    } catch (e) {
      debugPrint('播放失败: $e');
    }
  }

  void setVolume({required PlayingSound playingSound, required double volume}) {
    // media_kit 音量范围是 0-100
    playingSound.player.setVolume((volume * 100).clamp(0.0, 100.0));
  }

  void setAllVolume(double volume) {
    volume = volume.clamp(0.0, 1.0);
    for (var playingSound in _playingMap.values) {
      playingSound.player.setVolume(volume * 100);
    }
  }

  void stop(SoundAsset asset) {
    final playingSound = _playingMap[asset.id];
    if (playingSound == null) throw '音频未在播放';
    playingSound.player.dispose();
    if (_playingMap.length == 1) _audioHandler.stop();
    notifyListeners();

    _playingMap.remove(playingSound.asset.id);
  }

  void stopAll() {
    for (var playingSound in _playingMap.values) {
      playingSound.player.dispose();
    }
    _audioHandler.stop();
    notifyListeners();
    _playingMap.clear();
  }

  bool isPlaying(SoundAsset sound) {
    return _playingMap.containsKey(sound.id);
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}

// /// 自定义音频处理器，处理系统媒体控制事件
class SoundPlayerHandler extends BaseAudioHandler {
  final AudioSession audioSession;

  SoundPlayerHandler(this.audioSession) {
    mediaItem.add(_mediaItem);
  }

  final _mediaItem = MediaItem(
    id: Constant.appName,
    title: Constant.appName,
    artist: Constant.appName,
    duration: const Duration(seconds: 1),
  );

  @override
  Future<void> play() async {
    print('SoundPlayerHandler播放');
    super.play();
    audioSession.setActive(true);
    mediaItem.add(_mediaItem);
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          MediaControl.pause,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: AudioProcessingState.ready,
        playing: true,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1,
      ),
    );
  }

  @override
  Future<void> stop() async {
    print('SoundPlayerHandler停止');
    super.stop();
    audioSession.setActive(false);
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }
}
