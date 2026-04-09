import 'package:niceleep/ai/model/rule/base_rule.dart';
import 'package:niceleep/ai/model/rule/search_rule.dart';
import 'package:niceleep/ai/model/rule/specific_sound_rule.dart';
import 'package:niceleep/ai/model/rule/category_rule.dart';
import 'package:niceleep/ai/model/rule/help_rule.dart';

class RuleManager {
  RuleManager._();

  static final RuleManager instance = RuleManager._();

  final List<BaseRule> _rules = [];

  void initialize() {
    _rules.clear();
    _rules.addAll([
      HelpRule(),
      SearchRule(),
      SpecificSoundRule(),
      CategoryRule(),
    ]);
  }

  List<BaseRule> get rules => List.unmodifiable(_rules);

  Future<RuleResult?> matchAndExecute(String prompt) async {
    for (final rule in _rules) {
      if (rule.matches(prompt)) {
        return await rule.execute(prompt);
      }
    }
    return null;
  }

  void addRule(BaseRule rule) {
    _rules.add(rule);
  }

  void removeRule(String name) {
    _rules.removeWhere((rule) => rule.name == name);
  }
}
