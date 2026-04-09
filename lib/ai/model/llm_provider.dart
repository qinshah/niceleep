abstract class LlmProvider {
  Future<String> generateResponse(String prompt);
  Stream<String> generateResponseStream(String prompt);
  String get name;
}
