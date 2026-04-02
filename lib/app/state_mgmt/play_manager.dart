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

class PlayManager extends BaseAudioHandler with SeekHandler, ChangeNotifier {
  late final AudioSession _audioSession;

  final _mediaItem = MediaItem(
    id: Constant.appName,
    title: Constant.appName,
    artist: Constant.appName,
    duration: Duration.zero,
    artUri: Uri.parse(Constant.logoUrl),
  );
  PlayManager._();

  static final PlayManager i = PlayManager._();

  /// 播放列表
  final _playList = <String, PlayingSound>{};
  List<PlayingSound> get playingSounds => _playList.values.toList();

  int _maxSoundCount = 10;

  int get maxSoundCount => _maxSoundCount;

  // 初始化时从 Hive 加载最大声音数量
  Future<void> init() async {
    // 初始化 AudioHandler 用于系统媒体通知
    await AudioService.init(
      builder: () => this,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
    mediaItem.add(_mediaItem);
    AudioSession.instance.then((session) {
      _audioSession = session;
      _audioSession.setActive(true);
    });
    playbackState.add(PlaybackState(playing: false));
    notifyListeners();
    _maxSoundCount = await ConfigService.getMaxSoundCount();
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

  bool countMaximum() => _playList.length >= _maxSoundCount;

  Future<void> playNew(SoundAsset asset) async {
    assert(!_playList.containsKey(asset.id), '此音频已在播放');
    assert(_playList.length < _maxSoundCount, '数量溢出');

    // 创建 media_kit Player
    final player = Player();
    notifyListeners(); // 先刷新UI
    _playList[asset.id] = PlayingSound(asset: asset, player: player);

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
      stopByAsset(asset); // 加载失败时调用stop以免UI错误
    } else {
      _setIslandPlaying(true); // 灵动岛显示播放中
      player.open(media);
      // 设置为循环播放
      player.setPlaylistMode(PlaylistMode.loop);
      // 设置默认音量 0.66
      player.setVolume(66); // media_kit 音量范围是 0-100}
      player.play().then((_) {
        notifyListeners(); // 通知UI：播放中
      });
    }
  }

  void setVolume({required PlayingSound playingSound, required double volume}) {
    // media_kit 音量范围是 0-100
    playingSound.player.setVolume((volume * 100).clamp(0.0, 100.0));
  }

  void setAllVolume(double volume) {
    volume = volume.clamp(0.0, 1.0);
    for (var playingSound in _playList.values) {
      playingSound.player.setVolume(volume * 100);
    }
  }

  void stopByAsset(SoundAsset asset) {
    final playingSound = _playList[asset.id];
    if (playingSound == null) throw '音频未在播放';
    playingSound.player.dispose();
    _playList.remove(playingSound.asset.id);
    notifyListeners(); // 通知UI：更新播放列表
    _playList.isEmpty
        ? stop() // 停止灵动岛
        : _updateIslandTitle(); // 更新灵动岛标题
  }

  void stopAll() {
    for (var playingSound in _playList.values) {
      playingSound.player.dispose();
    }
    stop(); // 停止灵动岛
    _playList.clear();
    notifyListeners(); // 通知UI：已清空播放列表
  }

  bool isPlaying(SoundAsset sound) {
    return _playList.containsKey(sound.id);
  }

  bool? isPausing(SoundAsset sound) {
    final playingSound = _playList[sound.id];
    if (playingSound == null) {
      debugPrint('未找到播放音频');
      return null;
    }
    return !playingSound.player.state.playing;
  }

  void resume(SoundAsset sound) {
    _setIslandPlaying(true); // 灵动岛展示播放中
    final playingSound = _playList[sound.id];
    if (playingSound == null) throw '音频未在播放';
    playingSound.player.play().then((_) {
      notifyListeners(); // 通知IU：播放中
    });
  }

  Future<void> resumeAll() async {
    _setIslandPlaying(true); // 灵动岛展示播放中
    // 收集所有播放操作
    final futures = playingSounds
        .map((playingSound) => playingSound.player.play())
        .toList();
    await Future.wait(futures); // 并发执行所有播放操作
    notifyListeners(); // 通知UI：播放中
  }

  Future<void> pauseAll() async {
    _setIslandPlaying(false); // 灵动岛显示暂停
    // 收集所有暂停操作
    final futures = playingSounds
        .map((playingSound) => playingSound.player.pause())
        .toList();
    await Future.wait(futures); // 并发执行所有暂停操作
    notifyListeners(); // 通知IU：暂停中
  }

  /// 设置灵动岛是否显示播放中
  void _setIslandPlaying(bool playing) {
    playbackState.add(
      PlaybackState(
        playing: playing,
        processingState: playing
            ? AudioProcessingState.completed
            : AudioProcessingState.ready,
      ),
    );
    if (playing) _updateIslandTitle();
  }

  /// 更新灵动岛标题
  void _updateIslandTitle() {
    mediaItem.add(
      _mediaItem.copyWith(
        title: _playList.values
            .map((playingSound) => playingSound.asset.name)
            .join(' '),
      ),
    );
  }

  @override // 从灵动岛播放
  Future<void> play() async {
    resumeAll(); // 播放所有
  }

  @override //从灵动岛暂停
  Future<void> pause() async {
    pauseAll(); // 暂停所有
  }

  /// 停止灵动岛
  @override
  Future<void> stop() {
    _audioSession.setActive(false);
    playbackState.add(
      PlaybackState(playing: false, processingState: AudioProcessingState.idle),
    );
    mediaItem.add(null);
    return super.stop();
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}
