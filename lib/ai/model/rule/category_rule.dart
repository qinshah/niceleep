import 'package:niceleep/ai/model/rule/base_rule.dart';

class CategoryRule implements BaseRule {
  final Map<String, List<String>> _keywordToCategories = {
    '睡觉': ['nature', 'rain', 'noise'],
    '失眠': ['noise', 'nature', 'rain'],
    '放松': ['nature', 'things', 'rain'],
    '压力': ['nature', 'noise', 'rain'],
    '工作': ['noise', 'places', 'things'],
    '学习': ['noise', 'nature', 'things'],
    '专注': ['noise', 'nature', 'things'],
    '冥想': ['nature', 'things', 'noise'],
    '焦虑': ['nature', 'rain', 'noise'],
    '雨声': ['rain'],
    '自然': ['nature'],
    '白噪音': ['noise'],
    '动物': ['animals'],
    '城市': ['urban'],
    '交通': ['transport'],
    '场所': ['places'],
    '物品': ['things'],
  };

  @override
  String get name => 'category';

  @override
  List<String> get keywords => _keywordToCategories.keys.toList();

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
    List<String> matchedCategories = [];

    for (final entry in _keywordToCategories.entries) {
      if (lowerPrompt.contains(entry.key.toLowerCase())) {
        matchedCategories.addAll(entry.value);
        break;
      }
    }

    return RuleResult(
      responseType: 'category',
      searchTerm: matchedCategories.first,
      prefixMessage: '好的，根据您的需求，我为您推荐以下音频：',
      suffixMessage: '您可以点击任意音频开始播放。如果需要其他推荐，请随时告诉我！',
    );
  }
}
