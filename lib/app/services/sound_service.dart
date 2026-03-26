import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data_model/sound_asset.dart';
import '../data_model/sound_category.dart';

/// 音频资源服务
/// 负责从 assets/sounds.json 加载音频清单，提供音频查询功能
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  /// 所有音频列表
  final List<SoundAsset> _sounds = [];

  /// 所有音频类别列表
  final List<SoundCategory> _categories = [];

  /// 是否已初始化
  bool _isInitialized = false;

  /// 分类名称映射（category id -> category name）
  final Map<String, String> _categoryIdToName = {};

  /// 分类图标映射（category id -> icon）
  final Map<String, IconData> _categoryIdToIcon = {};

  /// 获取所有音频
  List<SoundAsset> get sounds => List.unmodifiable(_sounds);

  /// 获取所有类别
  List<SoundCategory> get categories => List.unmodifiable(_categories);

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化服务，加载 sounds.json
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 加载 sounds.json
      final jsonString = await rootBundle.loadString('assets/sounds.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 解析类别
      final categoriesJson = jsonData['categories'] as List<dynamic>? ?? [];
      _categories.clear();
      for (final categoryJson in categoriesJson) {
        final category = SoundCategory.fromJson(categoryJson as Map<String, dynamic>);
        _categories.add(category);
        _categoryIdToName[category.id] = category.name;
        _categoryIdToIcon[category.id] = category.icon;
      }

      // 按 order 排序类别
      _categories.sort((a, b) => a.order.compareTo(b.order));

      // 解析音频
      final soundsJson = jsonData['sounds'] as List<dynamic>? ?? [];
      _sounds.clear();
      for (final soundJson in soundsJson) {
        final soundData = soundJson as Map<String, dynamic>;
        
        // 获取分类信息
        final categoryId = soundData['category'] as String;
        final categoryName = _categoryIdToName[categoryId] ?? categoryId;
        final categoryIcon = _categoryIdToIcon[categoryId] ?? Icons.audiotrack;

        // 生成完整的音频 ID（category_id）
        final soundId = soundData['id'] as String;
        final fullId = '${categoryId}_$soundId';

        _sounds.add(SoundAsset(
          id: fullId,
          name: soundData['name'] as String,
          path: soundData['path'] as String,
          category: categoryName,
          icon: categoryIcon,
          description: soundData['nameZhTW'] as String?,
          nameEn: soundData['nameEn'] as String?,
          nameZhTW: soundData['nameZhTW'] as String?,
          order: soundData['order'] as int?,
          isSeamless: soundData['isSeamless'] as bool?,
          loopStart: (soundData['loopStart'] as num?)?.toDouble(),
          loopEnd: (soundData['loopEnd'] as num?)?.toDouble(),
          format: soundData['format'] as String?,
        ));
      }

      // 按 order 排序音频
      _sounds.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize SoundService: $e');
      rethrow;
    }
  }

  /// 获取所有分类名称（包含"全部"选项）
  List<String> getCategoryNames() {
    final names = ['全部'];
    for (final category in _categories) {
      names.add(category.name);
    }
    return names;
  }

  /// 根据分类获取音频列表
  List<SoundAsset> getSoundsByCategory(String categoryName) {
    if (categoryName == '全部') {
      return sounds;
    }
    return _sounds.where((s) => s.category == categoryName).toList();
  }

  /// 根据分类ID获取音频列表
  List<SoundAsset> getSoundsByCategoryId(String categoryId) {
    return _sounds.where((s) {
      final categoryName = _categoryIdToName[categoryId];
      return s.category == categoryName;
    }).toList();
  }

  /// 根据 ID 获取音频
  SoundAsset? getSoundById(String id) {
    try {
      return _sounds.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据分类ID获取类别
  SoundCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// 获取按分类分组的音频
  Map<String, List<SoundAsset>> getSoundsGroupedByCategory() {
    final grouped = <String, List<SoundAsset>>{};
    for (final sound in _sounds) {
      final categoryName = sound.category;
      if (!grouped.containsKey(categoryName)) {
        grouped[categoryName] = [];
      }
      grouped[categoryName]!.add(sound);
    }
    return grouped;
  }

  /// 获取分类ID到名称的映射
  Map<String, String> get categoryIdToName => Map.unmodifiable(_categoryIdToName);

  /// 获取分类ID到图标的映射
  Map<String, IconData> get categoryIdToIcon => Map.unmodifiable(_categoryIdToIcon);

  /// 搜索音频
  List<SoundAsset> searchSounds(String query) {
    if (query.isEmpty) return sounds;
    
    final lowerQuery = query.toLowerCase();
    return _sounds.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          (s.nameEn?.toLowerCase().contains(lowerQuery) ?? false) ||
          s.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
