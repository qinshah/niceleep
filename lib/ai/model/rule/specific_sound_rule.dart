import 'package:niceleep/ai/model/rule/base_rule.dart';

class SpecificSoundRule implements BaseRule {
  final Map<String, List<String>> _keywordToSounds = {
    '下雨': ['light-rain', 'heavy-rain', 'rain-on-umbrella'],
    '海浪': ['waves'],
    '河流': ['river'],
    '篝火': ['campfire'],
    '森林': ['jungle', 'wind-in-trees'],
    '蟋蟀': ['crickets'],
    '鸟鸣': ['birds'],
    '白噪音': ['white-noise'],
    '粉红噪音': ['pink-noise'],
    '棕噪音': ['brown-noise'],
    '钢琴': ['light-piano', 'piano'],
    '风铃': ['wind-chimes'],
  };

  @override
  String get name => 'specific_sound';

  @override
  List<String> get keywords => _keywordToSounds.keys.toList();

  @override
  bool matches(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    for (final keyword in keywords) {
      if (lowerPrompt.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<RuleResult> execute(String prompt) async {
    final lowerPrompt = prompt.toLowerCase();
    List<String> matchedSoundIds = [];

    for (final entry in _keywordToSounds.entries) {
      if (lowerPrompt.contains(entry.key.toLowerCase())) {
        matchedSoundIds.addAll(entry.value);
        break;
      }
    }

    return RuleResult(
      responseType: 'specific',
      soundIds: matchedSoundIds,
      prefixMessage: '好的，根据您的需求，我为您推荐以下音频：',
      suffixMessage: '您可以点击任意音频开始播放。如果需要其他推荐，请随时告诉我！',
    );
  }
}
