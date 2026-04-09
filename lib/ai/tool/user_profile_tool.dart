import 'package:niceleep/ai/tool/mcp_tool.dart';
import 'package:hive_ce/hive_ce.dart';

class UserProfile {
  final String userId;
  final Map<String, int> soundPlayCounts;
  final List<String> favoriteSounds;
  final List<String> recentSearches;
  final DateTime createdAt;
  DateTime? lastActiveAt;

  UserProfile({
    required this.userId,
    this.soundPlayCounts = const {},
    this.favoriteSounds = const [],
    this.recentSearches = const [],
    required this.createdAt,
    this.lastActiveAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'soundPlayCounts': soundPlayCounts,
      'favoriteSounds': favoriteSounds,
      'recentSearches': recentSearches,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      soundPlayCounts: Map<String, int>.from(json['soundPlayCounts'] as Map? ?? {}),
      favoriteSounds: List<String>.from(json['favoriteSounds'] as List? ?? []),
      recentSearches: List<String>.from(json['recentSearches'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt'] as String) : null,
    );
  }
}

class UserProfileTool implements McpTool {
  UserProfile? _currentProfile;
  static const String _boxName = 'userProfiles';
  static const String _defaultUserId = 'default_user';

  @override
  String get name => 'user_profile';

  @override
  String get description => '管理用户偏好、收藏和播放历史';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['get', 'add_favorite', 'remove_favorite', 'record_play', 'add_search'],
            'description': '要执行的操作',
          },
          'sound_id': {
            'type': 'string',
            'description': '音频 ID（用于 add_favorite, remove_favorite, record_play）',
          },
          'search_query': {
            'type': 'string',
            'description': '搜索查询（用于 add_search）',
          },
        },
        'required': ['action'],
      };

  Future<UserProfile> _getOrCreateProfile() async {
    if (_currentProfile != null) {
      return _currentProfile!;
    }

    final box = await Hive.openBox<Map>(_boxName);
    final data = box.get(_defaultUserId);

    if (data != null) {
      _currentProfile = UserProfile.fromJson(Map<String, dynamic>.from(data));
    } else {
      _currentProfile = UserProfile(
        userId: _defaultUserId,
        createdAt: DateTime.now(),
      );
      await _saveProfile();
    }

    return _currentProfile!;
  }

  Future<void> _saveProfile() async {
    if (_currentProfile == null) return;
    final box = await Hive.openBox<Map>(_boxName);
    await box.put(_defaultUserId, _currentProfile!.toJson());
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final action = args['action'] as String;
    final profile = await _getOrCreateProfile();
    profile.lastActiveAt = DateTime.now();

    try {
      switch (action) {
        case 'get':
          return {
            'success': true,
            'profile': profile.toJson(),
          };

        case 'add_favorite':
          final soundId = args['sound_id'] as String?;
          if (soundId == null) {
            return {'success': false, 'error': 'sound_id is required'};
          }
          if (!profile.favoriteSounds.contains(soundId)) {
            profile.favoriteSounds.add(soundId);
          }
          await _saveProfile();
          return {
            'success': true,
            'action': 'add_favorite',
            'sound_id': soundId,
          };

        case 'remove_favorite':
          final soundId = args['sound_id'] as String?;
          if (soundId == null) {
            return {'success': false, 'error': 'sound_id is required'};
          }
          profile.favoriteSounds.remove(soundId);
          await _saveProfile();
          return {
            'success': true,
            'action': 'remove_favorite',
            'sound_id': soundId,
          };

        case 'record_play':
          final soundId = args['sound_id'] as String?;
          if (soundId == null) {
            return {'success': false, 'error': 'sound_id is required'};
          }
          profile.soundPlayCounts[soundId] = (profile.soundPlayCounts[soundId] ?? 0) + 1;
          await _saveProfile();
          return {
            'success': true,
            'action': 'record_play',
            'sound_id': soundId,
            'play_count': profile.soundPlayCounts[soundId],
          };

        case 'add_search':
          final searchQuery = args['search_query'] as String?;
          if (searchQuery == null) {
            return {'success': false, 'error': 'search_query is required'};
          }
          profile.recentSearches.remove(searchQuery);
          profile.recentSearches.insert(0, searchQuery);
          if (profile.recentSearches.length > 20) {
            profile.recentSearches.removeLast();
          }
          await _saveProfile();
          return {
            'success': true,
            'action': 'add_search',
            'search_query': searchQuery,
          };

        default:
          return {'success': false, 'error': 'Unknown action: $action'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
