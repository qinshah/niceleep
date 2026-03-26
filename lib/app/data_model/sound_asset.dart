import 'package:flutter/material.dart';

/// 音频资源数据模型
class SoundAsset {
  final String id;
  final String name;
  final String path;
  final String category;
  final IconData icon;
  final String? description;

  /// 额外的元数据字段（从 sounds.json 扩展）
  final String? nameEn;
  final String? nameZhTW;
  final int? order;
  final bool? isSeamless;
  final double? loopStart;
  final double? loopEnd;
  final String? format;

  SoundAsset({
    required this.id,
    required this.name,
    required this.path,
    required this.category,
    required this.icon,
    this.description,
    this.nameEn,
    this.nameZhTW,
    this.order,
    this.isSeamless,
    this.loopStart,
    this.loopEnd,
    this.format,
  });

  /// 从 JSON 创建
  factory SoundAsset.fromJson(Map<String, dynamic> json) {
    return SoundAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String? ?? json['url'] as String,
      category: json['category'] as String,
      icon: IconData(json['iconCode'] as int? ?? 0xe405, fontFamily: 'MaterialIcons'),
      description: json['description'] as String?,
      nameEn: json['nameEn'] as String?,
      nameZhTW: json['nameZhTW'] as String?,
      order: json['order'] as int?,
      isSeamless: json['isSeamless'] as bool?,
      loopStart: (json['loopStart'] as num?)?.toDouble(),
      loopEnd: (json['loopEnd'] as num?)?.toDouble(),
      format: json['format'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'category': category,
      'iconCode': icon.codePoint,
      'description': description,
      'nameEn': nameEn,
      'nameZhTW': nameZhTW,
      'order': order,
      'isSeamless': isSeamless,
      'loopStart': loopStart,
      'loopEnd': loopEnd,
      'format': format,
    };
  }

  /// 创建副本（带可选覆盖字段）
  SoundAsset copyWith({
    String? id,
    String? name,
    String? path,
    String? category,
    IconData? icon,
    String? description,
    String? nameEn,
    String? nameZhTW,
    int? order,
    bool? isSeamless,
    double? loopStart,
    double? loopEnd,
    String? format,
  }) {
    return SoundAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      nameEn: nameEn ?? this.nameEn,
      nameZhTW: nameZhTW ?? this.nameZhTW,
      order: order ?? this.order,
      isSeamless: isSeamless ?? this.isSeamless,
      loopStart: loopStart ?? this.loopStart,
      loopEnd: loopEnd ?? this.loopEnd,
      format: format ?? this.format,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundAsset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SoundAsset(id: $id, name: $name, category: $category)';
  }
}
