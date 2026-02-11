import 'dart:convert';
import 'dart:io';

void main() async {
  final env = {'此环境变量由脚本自动生成': '请勿编辑', 'isStoreVersion': true};
  File('./.vscode/env.json')
    ..createSync()
    ..writeAsStringSync(jsonEncode(env));
}
