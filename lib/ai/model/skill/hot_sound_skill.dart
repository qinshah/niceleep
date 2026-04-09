import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/sound_service.dart';

class HotSoundSkill {
  HotSoundSkill._();

  static final HotSoundSkill instance = HotSoundSkill._();

  List<SoundAsset> getRandomHotSounds({int count = 3}) {
    final soundService = SoundService.instance;
    final allSounds = soundService.sounds.toList();
    allSounds.shuffle();
    return allSounds.take(count).toList();
  }

  List<SoundAsset> getTopHotSounds({int count = 3}) {
    final soundService = SoundService.instance;
    final hotSoundIds = [
      'white-noise',
      'rain-on-umbrella',
      'waves',
      'river',
      'crickets',
      'campfire',
    ];
    final List<SoundAsset> hotSounds = [];
    for (final id in hotSoundIds) {
      final sound = soundService.getSoundById(id);
      if (sound != null) {
        hotSounds.add(sound);
      }
    }
    if (hotSounds.length < count) {
      hotSounds.addAll(getRandomHotSounds(count: count - hotSounds.length));
    }
    return hotSounds.take(count).toList();
  }
}
