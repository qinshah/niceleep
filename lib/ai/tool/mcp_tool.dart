abstract class McpTool {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args);
}
