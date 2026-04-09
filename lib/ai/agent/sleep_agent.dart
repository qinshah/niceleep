import 'dart:async';
import 'package:niceleep/ai/model/llm_provider.dart';
import 'package:niceleep/ai/tool/mcp_tool.dart';
import 'package:niceleep/ai/tool/sleep_knowledge_tool.dart';
import 'package:niceleep/ai/tool/audio_control_tool.dart';
import 'package:niceleep/ai/tool/user_profile_tool.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class SleepAgent {
  final LlmProvider llmProvider;
  final List<ChatMessage> _messages = [];
  final List<McpTool> _tools = [];

  SleepAgent({required this.llmProvider}) {
    _initTools();
  }

  void _initTools() {
    _tools.addAll([
      SleepKnowledgeTool(),
      AudioControlTool(),
      UserProfileTool(),
    ]);
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addMessage(ChatMessage message) {
    _messages.add(message);
    if (_messages.length > 50) {
      _messages.removeAt(0);
    }
  }

  void clearHistory() {
    _messages.clear();
  }

  Future<String> sendMessage(String userMessage) async {
    addMessage(ChatMessage(role: 'user', content: userMessage));

    final response = await llmProvider.generateResponse(userMessage);

    addMessage(ChatMessage(role: 'assistant', content: response));

    return response;
  }

  Stream<String> sendMessageStream(String userMessage) async* {
    addMessage(ChatMessage(role: 'user', content: userMessage));

    final response = await llmProvider.generateResponse(userMessage);
    
    final words = response.split('');
    final buffer = StringBuffer();
    
    for (final char in words) {
      buffer.write(char);
      await Future.delayed(const Duration(milliseconds: 10));
      yield buffer.toString();
    }

    addMessage(ChatMessage(role: 'assistant', content: response));
  }

  Future<Map<String, dynamic>> executeTool(String toolName, Map<String, dynamic> args) async {
    final tool = _tools.firstWhere(
      (t) => t.name == toolName,
      orElse: () => throw Exception('Tool not found: $toolName'),
    );
    return await tool.execute(args);
  }

  List<McpTool> get availableTools => List.unmodifiable(_tools);
}
