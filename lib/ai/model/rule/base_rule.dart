abstract class BaseRule {
  String get name;
  List<String> get keywords;
  bool matches(String prompt);
  Future<RuleResult> execute(String prompt);
}

class RuleResult {
  final String responseType;
  final String? prefixMessage;
  final String? suffixMessage;
  final List<String>? soundIds;
  final String? searchTerm;

  RuleResult({
    required this.responseType,
    this.prefixMessage,
    this.suffixMessage,
    this.soundIds,
    this.searchTerm,
  });
}
