import 'package:niceleep/ai/model/rule/base_rule.dart';

class SearchRule implements BaseRule {
  @override
  String get name => 'search';

  @override
  List<String> get keywords => [
    '搜索',
    '查找',
    '寻找',
    '检索',
    '有没有',
    '找',
  ];

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
    String? searchTerm;

    for (final keyword in keywords) {
      if (lowerPrompt.contains(keyword.toLowerCase())) {
        searchTerm = lowerPrompt.replaceAll(keyword.toLowerCase(), '').trim();
        break;
      }
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      return RuleResult(
        responseType: 'search',
        searchTerm: searchTerm,
        prefixMessage: '我找到了以下相关音频：',
        suffixMessage: '您可以点击任意音频开始播放。需要搜索其他音频，请告诉我！',
      );
    } else {
      return RuleResult(
        responseType: 'search_empty',
        prefixMessage: '请告诉我您想搜索什么音频，例如："搜索雨声"',
      );
    }
  }
}
