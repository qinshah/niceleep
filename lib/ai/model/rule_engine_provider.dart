import 'dart:async';
import 'package:niceleep/ai/model/llm_provider.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/sound_service.dart';

class RuleEngineProvider implements LlmProvider {
  @override
  String get name => 'RuleEngine';

  final Map<String, List<String>> _keywordToCategories = {
    '睡觉': ['nature', 'rain', 'noise'],
    '失眠': ['noise', 'nature', 'rain'],
    '放松': ['nature', 'things', 'rain'],
    '压力': ['nature', 'noise', 'rain'],
    '工作': ['noise', 'places', 'things'],
    '学习': ['noise', 'nature', 'things'],
    '专注': ['noise', 'nature', 'things'],
    '冥想': ['nature', 'things', 'noise'],
    '焦虑': ['nature', 'rain', 'noise'],
    '雨声': ['rain'],
    '自然': ['nature'],
    '白噪音': ['noise'],
    '动物': ['animals'],
    '城市': ['urban'],
    '交通': ['transport'],
    '场所': ['places'],
    '物品': ['things'],
  };

  final Map<String, List<String>> _keywordToSounds = {
    '下雨': ['light-rain', 'heavy-rain', 'rain-on-umbrella'],
    '海浪': ['waves'],
    '河流': ['river'],
    '篝火': ['campfire'],
    '森林': ['jungle', 'wind-in-trees'],
    '蟋蟀': ['crickets'],
    '鸟鸣': ['birds'],
    '白噪音': ['white-noise'],
    '粉红噪音': ['pink-noise'],
    '棕噪音': ['brown-noise'],
    '钢琴': ['light-piano', 'piano'],
    '风铃': ['wind-chimes'],
  };

  @override
  Future<String> generateResponse(String prompt) async {
    final recommendation = _generateRecommendation(prompt);
    return _formatResponse(recommendation);
  }

  @override
  Stream<String> generateResponseStream(String prompt) async* {
    final recommendation = _generateRecommendation(prompt);
    final response = _formatResponse(recommendation);
    
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield response.substring(0, i + 1);
    }
  }

  RecommendationResult _generateRecommendation(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final soundService = SoundService.instance;
    
    List<SoundAsset> recommendedSounds = [];
    String responseType = 'general';
    bool foundMatch = false;

    for (final entry in _keywordToSounds.entries) {
      if (lowerPrompt.contains(entry.key.toLowerCase())) {
        foundMatch = true;
        for (final soundId in entry.value) {
          final sound = soundService.searchSounds(soundId);
          if (sound.isNotEmpty) {
            recommendedSounds.addAll(sound);
          }
        }
        responseType = 'specific';
        break;
      }
    }

    if (!foundMatch) {
      for (final entry in _keywordToCategories.entries) {
        if (lowerPrompt.contains(entry.key.toLowerCase())) {
          foundMatch = true;
          for (final categoryId in entry.value) {
            final sounds = soundService.getSoundsByCategoryId(categoryId);
            recommendedSounds.addAll(sounds.take(2));
          }
          responseType = 'category';
          break;
        }
      }
    }

    if (!foundMatch) {
      recommendedSounds = soundService.sounds.take(3).toList();
      responseType = 'default';
    }

    recommendedSounds = recommendedSounds.toSet().toList();
    if (recommendedSounds.length > 3) {
      recommendedSounds = recommendedSounds.sublist(0, 3);
    }

    return RecommendationResult(
      sounds: recommendedSounds,
      responseType: responseType,
      userPrompt: prompt,
    );
  }

  String _formatResponse(RecommendationResult result) {
    final buffer = StringBuffer();
    
    buffer.writeln('好的，根据您的需求，我为您推荐以下音频：\n');
    
    for (int i = 0; i < result.sounds.length; i++) {
      final sound = result.sounds[i];
      buffer.writeln('${i + 1}. **${sound.name}** (${sound.category})');
      buffer.writeln('   - 可以帮助您放松身心，改善睡眠质量\n');
    }
    
    buffer.writeln('您可以点击任意音频开始播放。如果需要其他推荐，请随时告诉我！');
    
    return buffer.toString();
  }
}

class RecommendationResult {
  final List<SoundAsset> sounds;
  final String responseType;
  final String userPrompt;

  RecommendationResult({
    required this.sounds,
    required this.responseType,
    required this.userPrompt,
  });
}
