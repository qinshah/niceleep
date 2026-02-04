import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:niceleep/app/data_model/playing_sound.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/config_service.dart';

class SoundManager extends ChangeNotifier {
  SoundManager._();
  //  {
  //   AudioSession.instance.then((audioSession) {
  //     audioSession.configure(AudioSessionConfiguration.music());
  //     _audioSession = audioSession;
  //   });
  // }
  static final SoundManager i = SoundManager._();
  final _playingMap = <String, PlayingSound>{};
  List<PlayingSound> get playingSounds => _playingMap.values.toList();

  // late final AudioSession _audioSession;

  int _maxSoundCount = 10;

  int get maxSoundCount => _maxSoundCount;

  // 初始化时从Hive加载最大声音数量
  Future<void> init() async {
    _maxSoundCount = await ConfigService.getMaxSoundCount();
    notifyListeners();
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
    // 否则添加到播放列表
    final player = AudioPlayer(playerId: asset.id);
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
    await player.setSource(AssetSource(asset.path.replaceFirst('assets/', '')));
    await player.setReleaseMode(ReleaseMode.loop); // 设置为循环播放
    await player.setVolume(0.5); // 默认0.5音量
    await player.resume();
    notifyListeners();
    _playingMap[asset.id] = PlayingSound(asset: asset, player: player);
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
    notifyListeners();
  }

  void stopAll() {
    for (var playingSound in _playingMap.values) {
      playingSound.player.dispose();
    }
    _playingMap.clear();
    notifyListeners();
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
