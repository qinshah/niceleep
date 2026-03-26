import 'package:media_kit/media_kit.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';

class PlayingSound {
  final SoundAsset asset;

  final Player player;

  PlayingSound({required this.player, required this.asset});
}
