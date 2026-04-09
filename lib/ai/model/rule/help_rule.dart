import 'package:niceleep/ai/model/rule/base_rule.dart';

class HelpRule implements BaseRule {
  @override
  String get name => 'help';

  @override
  List<String> get keywords => [
    '帮助',
    '怎么用',
    '使用方法',
    '说明',
    'help',
    'usage',
    'guide',
    '你好',
    '你是谁',
    '您好',
    '哈喽',
    'hi',
    'hello',
    '早上好',
    '下午好',
    '晚上好',
    '在吗',
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
    final greetingKeywords = [
      '你好', '你是谁', '您好', '哈喽', 'hi', 'hello', '早上好', '下午好', '晚上好', '在吗'
    ];
    
    for (final keyword in greetingKeywords) {
      if (lowerPrompt.contains(keyword.toLowerCase())) {
        final responses = [
          '你好！我是您的 AI 助眠助手！',
          '您好！很高兴为您服务！',
          '你好呀！有什么我可以帮助您的吗？',
        ];
        final randomIndex = DateTime.now().millisecond % responses.length;
        return RuleResult(
          responseType: 'greeting',
          prefixMessage: responses[randomIndex],
          suffixMessage: '我可以为您推荐助眠音频，您可以说："我失眠了"、"搜索雨声" 或 "找白噪音"',
        );
      }
    }

    return RuleResult(
      responseType: 'help',
      prefixMessage: '''
欢迎使用 AI 助眠助手！

【使用说明】
1. 直接描述您的需求，例如：
   - "我失眠了" → 推荐助眠音频
   - "想放松一下" → 推荐放松音频
   - "需要专注工作" → 推荐白噪音

2. 搜索特定音频：
   - "搜索雨声"
   - "找白噪音"
   - "有没有雨声"

3. 其他示例关键词：
   - 睡觉、失眠、放松、压力、工作、学习、专注、冥想、焦虑
   - 雨声、自然、白噪音、动物、城市、交通、场所、物品

4. 推荐音频后，可直接点击快捷按钮播放！
''',
      suffixMessage: '现在试试告诉我您的需求吧！',
    );
  }
}
