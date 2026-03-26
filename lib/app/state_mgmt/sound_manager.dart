import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart'
    hide AndroidAudioFocus, AVAudioSessionCategory;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:niceleep/app/constant.dart';
import 'package:niceleep/app/data_model/playing_sound.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/config_service.dart';
import 'package:os_type/os_type.dart';

class SoundManager extends ChangeNotifier {
  SoundManager._();

  static final SoundManager i = SoundManager._();
  final _playingMap = <String, PlayingSound>{};
  List<PlayingSound> get playingSounds => _playingMap.values.toList();

  int _maxSoundCount = 10;

  int get maxSoundCount => _maxSoundCount;

  AudioHandler? _audioHandler;
  AudioSession? _audioSession;

  // 初始化时从 Hive 加载最大声音数量
  Future<void> init() async {
    _maxSoundCount = await ConfigService.getMaxSoundCount();
    // 初始化音频服务和会话
    await _initAudioService();
    notifyListeners();
  }

  // 初始化音频服务和会话配置
  Future<void> _initAudioService() async {
    try {
      _audioSession = await AudioSession.instance;
      _audioSession!.configure(const AudioSessionConfiguration.music());
      
      // 初始化 AudioHandler 用于系统媒体通知
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: '${Constant.packageName}.audio',
          androidNotificationChannelName: '${Constant.appName}音频服务',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          fastForwardInterval: Duration(seconds: 10),
          rewindInterval: Duration(seconds: 10),
          androidNotificationChannelDescription: 'Media notification channel',
          androidNotificationIcon: 'drawable/ic_notification_icon',
        ),
      );
      debugPrint('AudioService 初始化成功: $_audioHandler');
    } catch (e) {
      debugPrint('初始化音频服务失败：$e');
    }
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

    final player = AudioPlayer(playerId: asset.id);

    // 配置单个播放器的音频上下文
    if (OS.isIOS || OS.isAndroid) {
      await player.setAudioContext(
        AudioContext(
          // 防止安卓停掉之前的音频
          android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          iOS: AudioContextIOS(
            // iOS 需要 mixWithOthers 才能混音
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    }

    await player.setSource(AssetSource(asset.path.replaceFirst('assets/', '')));
    await player.setReleaseMode(ReleaseMode.loop); // 设置为循环播放
    await player.setVolume(0.5); // 默认 0.5 音量

    await player.resume();

    // 监听播放器状态变化并同步到系统媒体中心
    player.onPlayerStateChanged.listen((state) {
      _syncPlayerStateToHandler(state);
    });

    // 更新系统媒体通知
    _updateMediaNotification();
    // 更新当前播放的媒体项
    _updateCurrentMediaItem(asset);
    _audioSession?.setActive(true);

    debugPrint('播放音频: ${asset.name}, 状态: ${player.state}');

    notifyListeners();
    _playingMap[asset.id] = PlayingSound(asset: asset, player: player);

    // 初始同步播放状态
    _syncPlayerStateToHandler(PlayerState.playing);
  }

  void setVolume({required PlayingSound playingSound, required double volume}) {
    playingSound.player.setVolume(volume.clamp(0.0, 1.0));
  }

  void setAllVolume(double volume) {
    volume = volume.clamp(0.0, 1.0);
    for (var playingSound in _playingMap.values) {
      playingSound.player.setVolume(volume);
    }
  }

  void stop(SoundAsset asset) {
    final playingSound = _playingMap[asset.id];
    if (playingSound == null) throw '音频未在播放';
    playingSound.player.dispose();
    _playingMap.remove(playingSound.asset.id);
    
    // 更新媒体通知
    _updateMediaNotification();
    // 同步停止状态到系统媒体中心
    if (_playingMap.isEmpty) {
      _syncPlayerStateToHandler(PlayerState.stopped);
    }
    
    notifyListeners();
  }

  void stopAll() {
    for (var playingSound in _playingMap.values) {
      playingSound.player.dispose();
    }
    _playingMap.clear();
    
    // 同步停止状态到系统媒体中心
    _syncPlayerStateToHandler(PlayerState.stopped);
    // 清除媒体队列
    _audioHandler?.updateQueue([]);
    
    notifyListeners();
  }

  // 更新系统媒体通知
  void _updateMediaNotification() {
    if (_audioHandler == null) return;

    final playingSounds = this.playingSounds;
    if (playingSounds.isEmpty) {
      // 没有播放内容时清除队列
      _audioHandler?.updateQueue([]);
      return;
    }

    // 构建媒体项列表
    final queue = playingSounds.map((playingSound) {
      return MediaItem(
        id: playingSound.asset.id,
        title: playingSound.asset.name,
        artist: '响入睡',
        album: '助眠音频',
        duration: Duration.zero, // 循环播放不需要设置时长
      );
    }).toList();

    // 更新播放队列
    _audioHandler?.updateQueue(queue);

    // 更新当前播放状态
    if (queue.isNotEmpty) {
      _audioHandler?.addQueueItems(queue);
      // 更新播放状态为播放中
      (_audioHandler as AudioPlayerHandler?)?.updatePlaybackState(
        playing: true,
        processingState: AudioProcessingState.ready,
      );
    }
  }

  // 将播放器状态同步到 AudioHandler
  void _syncPlayerStateToHandler(PlayerState state) {
    if (_audioHandler == null) {
      debugPrint('_syncPlayerStateToHandler: _audioHandler is null');
      return;
    }

    final isPlaying = state == PlayerState.playing;
    final processingState = isPlaying
        ? AudioProcessingState.ready
        : (state == PlayerState.stopped 
            ? AudioProcessingState.idle 
            : AudioProcessingState.buffering);

    debugPrint('_syncPlayerStateToHandler: isPlaying=$isPlaying, state=$state');
    
    (_audioHandler as AudioPlayerHandler?)?.updatePlaybackState(
      playing: isPlaying,
      processingState: processingState,
    );
  }

  // 更新当前播放的媒体项（用于系统媒体中心显示当前正在播放的内容）
  void _updateCurrentMediaItem(SoundAsset asset) {
    if (_audioHandler == null) return;

    final mediaItem = MediaItem(
      id: asset.id,
      title: asset.name,
      artist: '响入睡',
      album: '助眠音频',
      duration: Duration.zero,
    );

    _audioHandler?.updateMediaItem(mediaItem);
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }

  bool isPlaying(SoundAsset sound) {
    return _playingMap.containsKey(sound.id);
  }
}

// /// 自定义音频处理器，处理系统媒体控制事件
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  AudioPlayerHandler() {
    // 初始化播放状态
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
        MediaControl.stop,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.skipToPrevious,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  @override
  Future<void> play() async {
    debugPrint('AudioPlayerHandler: play() 被调用');
    // 触发所有播放器的播放
    for (var playingSound in SoundManager.i.playingSounds) {
      await playingSound.player.resume();
    }
    
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> pause() async {
    debugPrint('AudioPlayerHandler: pause() 被调用');
    // 触发所有播放器的暂停
    for (var playingSound in SoundManager.i.playingSounds) {
      await playingSound.player.pause();
    }
    
    playbackState.add(playbackState.value.copyWith(
      playing: false,
    ));
  }

  @override
  Future<void> stop() async {
    debugPrint('AudioPlayerHandler: stop() 被调用');
    SoundManager.i.stopAll();
    
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  /// 更新播放状态
  void updatePlaybackState({
    required bool playing,
    required AudioProcessingState processingState,
  }) {
    debugPrint('AudioPlayerHandler: updatePlaybackState playing=$playing, processingState=$processingState');
    playbackState.add(
      playbackState.value.copyWith(
        playing: playing,
        processingState: processingState,
      ),
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    debugPrint('AudioPlayerHandler: onTaskRemoved');
    // 停止所有播放
    await stop();
    await super.onTaskRemoved();
  }
}
