import 'package:niceleep/ai/tool/mcp_tool.dart';
import 'package:niceleep/app/services/sound_service.dart';

class SleepKnowledgeTool implements McpTool {
  @override
  String get name => 'sleep_knowledge';

  @override
  String get description => '查询睡眠知识和音频推荐信息';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': '用户的查询问题',
          },
        },
        'required': ['query'],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final query = args['query'] as String;
    final soundService = SoundService.instance;

    final results = soundService.searchSounds(query);
    final sounds = results.take(5).map((sound) => sound.toJson()).toList();

    return {
      'success': true,
      'query': query,
      'recommended_sounds': sounds,
      'total_count': results.length,
    };
  }
}
