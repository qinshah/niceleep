import 'package:niceleep/ai/tool/mcp_tool.dart';
import 'package:niceleep/app/services/sound_service.dart';
import 'package:niceleep/app/state_mgmt/play_manager.dart';

class AudioControlTool implements McpTool {
  @override
  String get name => 'audio_control';

  @override
  String get description => '控制音频播放、暂停和停止';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['play', 'pause', 'stop', 'stop_all'],
            'description': '要执行的操作',
          },
          'sound_id': {
            'type': 'string',
            'description': '音频的 ID（play/pause/stop 操作需要）',
          },
        },
        'required': ['action'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    final soundService = SoundService.instance;

    try {
      switch (action) {
        case 'play':
          final soundId = args['sound_id'] as String?;
          if (soundId == null) {
            return {'success': false, 'error': 'sound_id is required for play action'};
          }
          final sound = soundService.getSoundById(soundId);
          if (sound == null) {
            return {'success': false, 'error': 'Sound not found'};
          }
          PlayManager.i.playNew(sound);
          return {'success': true, 'action': 'play', 'sound_id': soundId};

        case 'pause':
          final soundId = args['sound_id'] as String?;
          if (soundId == null) {
            return {'success': false, 'error': 'sound_id is required for pause action'};
          }
          final sound = soundService.getSoundById(soundId);
          if (sound == null) {
            return {'success': false, 'error': 'Sound not found'};
          }
          final isPausing = PlayManager.i.isPausing(sound);
          if (isPausing == null) {
            return {'success': false, 'error': 'Sound is not playing'};
          }
          if (isPausing) {
            await PlayManager.i.resumeAll();
          } else {
            await PlayManager.i.pauseAll();
          }
          return {'success': true, 'action': 'pause', 'sound_id': soundId, 'new_state': isPausing ? 'resumed' : 'paused'};

        case 'stop':
          final soundId = args['sound_id'] as String?;
          if (soundId == null) {
            return {'success': false, 'error': 'sound_id is required for stop action'};
          }
          final sound = soundService.getSoundById(soundId);
          if (sound == null) {
            return {'success': false, 'error': 'Sound not found'};
          }
          PlayManager.i.stopByAsset(sound);
          return {'success': true, 'action': 'stop', 'sound_id': soundId};

        case 'stop_all':
          PlayManager.i.stopAll();
          return {'success': true, 'action': 'stop_all'};

        default:
          return {'success': false, 'error': 'Unknown action: $action'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
