import 'package:niceleep/ai/agent/sleep_agent.dart';
import 'package:niceleep/ai/model/llm_provider.dart';
import 'package:niceleep/ai/model/rule_engine_provider.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  SleepAgent? _agent;
  bool _isInitialized = false;

  SleepAgent get agent {
    if (_agent == null) {
      throw StateError('AiService not initialized. Call initialize() first.');
    }
    return _agent!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final llmProvider = RuleEngineProvider();
    _agent = SleepAgent(llmProvider: llmProvider);
    _isInitialized = true;
  }

  void switchProvider(LlmProvider provider) {
    _agent = SleepAgent(llmProvider: provider);
  }
}
