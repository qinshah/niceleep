import 'dart:async';
import 'package:niceleep/ai/model/llm_provider.dart';
import 'package:niceleep/ai/model/rule/rule_manager.dart';
import 'package:niceleep/ai/model/skill/hot_sound_skill.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/sound_service.dart';

class RuleEngineProvider implements LlmProvider {
  @override
  String get name => 'RuleEngine';

  RuleEngineProvider() {
    RuleManager.instance.initialize();
  }

  @override
  Future<String> generateResponse(String prompt) async {
    final recommendation = await _generateRecommendation(prompt);
    return _formatResponse(recommendation);
  }

  @override
  Stream<String> generateResponseStream(String prompt) async* {
    final recommendation = await _generateRecommendation(prompt);
    final response = _formatResponse(recommendation);
    
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield response.substring(0, i + 1);
    }
  }

  Future<RecommendationResult> _generateRecommendation(String prompt) async {
    final soundService = SoundService.instance;
    final hotSoundSkill = HotSoundSkill.instance;
    
    List<SoundAsset> recommendedSounds = [];
    String responseType = 'general';
    String? prefixMessage;
    String? suffixMessage;

    final ruleResult = await RuleManager.instance.matchAndExecute(prompt);

    if (ruleResult != null) {
      responseType = ruleResult.responseType;
      prefixMessage = ruleResult.prefixMessage;
      suffixMessage = ruleResult.suffixMessage;

      switch (responseType) {
        case 'search':
          if (ruleResult.searchTerm != null) {
            recommendedSounds = soundService.searchSounds(ruleResult.searchTerm!);
          }
          if (recommendedSounds.isEmpty) {
            recommendedSounds = hotSoundSkill.getTopHotSounds(count: 3);
            prefixMessage = '抱歉，没有找到"${ruleResult.searchTerm}"。给您推荐一些热门音频：';
          }
          break;
        case 'specific':
          if (ruleResult.soundIds != null) {
            for (final soundId in ruleResult.soundIds!) {
              final sound = soundService.searchSounds(soundId);
              if (sound.isNotEmpty) {
                recommendedSounds.addAll(sound);
              }
            }
          }
          break;
        case 'category':
          if (ruleResult.searchTerm != null) {
            final sounds = soundService.getSoundsByCategoryId(ruleResult.searchTerm!);
            recommendedSounds.addAll(sounds.take(2));
          }
          break;
        case 'greeting':
        case 'help':
        case 'search_empty':
          break;
        default:
          recommendedSounds = hotSoundSkill.getTopHotSounds(count: 3);
      }
    } else {
      responseType = 'confused';
      prefixMessage = '抱歉，我不太理解您的需求。为您推荐一些热门音频：';
      suffixMessage = '您可以点击任意音频开始播放。您也可以尝试说："我失眠了"、"推荐雨声" 或 "搜索白噪音"';
      recommendedSounds = hotSoundSkill.getTopHotSounds(count: 3);
    }

    recommendedSounds = recommendedSounds.toSet().toList();
    if (recommendedSounds.length > 3) {
      recommendedSounds = recommendedSounds.sublist(0, 3);
    }

    return RecommendationResult(
      sounds: recommendedSounds,
      responseType: responseType,
      userPrompt: prompt,
      prefixMessage: prefixMessage,
      suffixMessage: suffixMessage,
    );
  }

  String _formatResponse(RecommendationResult result) {
    final buffer = StringBuffer();
    
    if (result.prefixMessage != null) {
      buffer.writeln('${result.prefixMessage}\n');
    }
    
    if (result.sounds.isNotEmpty) {
      for (int i = 0; i < result.sounds.length; i++) {
        final sound = result.sounds[i];
        buffer.writeln('${i + 1}. **${sound.name}** (${sound.category})');
        buffer.writeln('   - 可以帮助您放松身心，改善睡眠质量\n');
      }
    }
    
    if (result.suffixMessage != null) {
      buffer.writeln(result.suffixMessage);
    } else if (result.sounds.isNotEmpty) {
      buffer.writeln('您可以点击任意音频开始播放。如果需要其他推荐，请随时告诉我！');
    }
    
    return buffer.toString();
  }
}

class RecommendationResult {
  final List<SoundAsset> sounds;
  final String responseType;
  final String userPrompt;
  final String? prefixMessage;
  final String? suffixMessage;

  RecommendationResult({
    required this.sounds,
    required this.responseType,
    required this.userPrompt,
    this.prefixMessage,
    this.suffixMessage,
  });
}
