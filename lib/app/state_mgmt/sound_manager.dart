import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
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

  late final SoundHandler _audioHandler;

  // 初始化时从 Hive 加载最大声音数量
  Future<void> init() async {
    // 初始化 AudioHandler 用于系统媒体通知
    _audioHandler = await AudioService.init(
      builder: () => SoundHandler(),
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

    // 创建 media_kit Player
    final player = Player();
    notifyListeners(); // 先刷新UI
    _playingMap[asset.id] = PlayingSound(asset: asset, player: player);

    final assetPath = asset.path;
    final assetUri = 'asset:///$assetPath';
    Playable? media;
    try {
      print('尝试加载asset: $assetUri');
      media = Media(assetUri);
    } catch (e) {
      print('加载asset失败: $e');
    }
    if (media == null) {
      try {
        final tempDir = Directory.systemTemp;
        final fileName = assetPath
            .replaceAll('/', '_')
            .replaceAll('assets_', '');
        final tempFile = File('${tempDir.path}/$fileName');
        // 检查临时文件是否已存在
        if (await tempFile.exists()) {
          debugPrint('使用已存在的临时文件: ${tempFile.path}');
        } else {
          // 读取 asset 字节并写入临时文件
          debugPrint('临时文件不存在，创建新文件');
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();
          await tempFile.writeAsBytes(bytes);
          debugPrint('临时文件路径: ${tempFile.path}');
        }
        media = Media(tempFile.path);
      } catch (e) {
        print('加载临时文件失败: $e');
      }
    }
    if (media == null) {
      notifyListeners();
      stop(asset); // 加载失败时调用stop以免UI错误
    } else {
      player.open(media);
      // 设置为循环播放
      player.setPlaylistMode(PlaylistMode.loop);
      // 设置默认音量 0.66
      player.setVolume(66); // media_kit 音量范围是 0-100}
      player.play();
      _audioHandler.play();
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

/// 自定义音频处理器，处理系统媒体控制事件
class SoundHandler extends BaseAudioHandler with SeekHandler {
  late final AudioSession _audioSession;

  SoundHandler() {
    mediaItem.add(_mediaItem);
    AudioSession.instance.then((session) {
      _audioSession = session;
      _audioSession.setActive(true);
    });
    playbackState.add(PlaybackState(playing: false));
  }

  final _mediaItem = MediaItem(
    id: Constant.appName,
    title: Constant.appName,
    artist: Constant.appName,
    duration: Duration.zero,
    artUri: Uri.parse('这个不能空'),
  );

  @override
  Future<void> play() async {
    _audioSession.setActive(true);
    playbackState.add(PlaybackState(playing: true));
  }

  @override
  Future<void> pause() async {
    print('从handler暂停');
    // TODO: 暂停
  }

  @override
  Future<void> stop() {
    _audioSession.setActive(false);
    playbackState.add(PlaybackState(playing: false));
    mediaItem.add(null);
    return super.stop();
  }
}
