import 'package:flutter/material.dart';

/// 音频类别数据模型
class SoundCategory {
  final String id;
  final String name;
  final String nameEn;
  final int order;
  final String nameZhTW;
  final IconData icon;

  const SoundCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.order,
    required this.nameZhTW,
    required this.icon,
  });

  /// 从 JSON 创建
  factory SoundCategory.fromJson(Map<String, dynamic> json) {
    return SoundCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      nameZhTW: json['nameZhTW'] as String? ?? json['name'] as String,
      icon: _getCategoryIcon(json['id'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'order': order,
      'nameZhTW': nameZhTW,
    };
  }

  /// 获取分类图标
  static IconData _getCategoryIcon(String categoryId) {
    const iconMap = <String, IconData>{
      'rain': Icons.water_drop,
      'nature': Icons.park,
      'noise': Icons.graphic_eq,
      'music': Icons.music_note,
      'urban': Icons.location_city,
      'places': Icons.place,
      'transport': Icons.directions_transit,
      'animals': Icons.pets,
      'things': Icons.toys,
    };
    return iconMap[categoryId] ?? Icons.audiotrack;
  }

  /// 预定义的分类图标映射（供外部使用）
  static const Map<String, IconData> categoryIcons = {
    'rain': Icons.water_drop,
    'nature': Icons.park,
    'noise': Icons.graphic_eq,
    'music': Icons.music_note,
    'urban': Icons.location_city,
    'places': Icons.place,
    'transport': Icons.directions_transit,
    'animals': Icons.pets,
    'things': Icons.toys,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
