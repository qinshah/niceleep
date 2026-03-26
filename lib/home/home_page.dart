import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niceleep/app/state_mgmt/sound_manager.dart';
import 'package:niceleep/app/data_model/sound_asset.dart';
import 'package:niceleep/app/services/sound_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategory = 0; // 0 = 全部

  List<String> get _categories => SoundService.instance.getCategoryNames();

  List<SoundAsset> get _filteredSounds {
    final category = _selectedCategory == 0
        ? '全部'
        : _categories[_selectedCategory];
    return SoundService.instance.getSoundsByCategory(category);
  }

  /// 获取按分类分组的声音（用于「全部」tab页）
  Map<String, List<SoundAsset>> get _groupedSounds {
    return SoundService.instance.getSoundsGroupedByCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '响入睡',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 16), _selectedCategory == 0
                ? _buildGroupedSoundsGrid()
                : _buildSoundsGrid(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlayingList(context),
        child: const Icon(Icons.list),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return FilterChip(
            selected: isSelected,
            label: Text(
              _categories[index],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            selectedColor: Theme.of(context).colorScheme.primary,
            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? index : 0;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSoundsGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredSounds.length,
        itemBuilder: (context, index) {
          final sound = _filteredSounds[index];
          return SoundCard(soundAsset: sound);
        },
      ),
    );
  }

  Widget _buildGroupedSoundsGrid() {
    final groupedSounds = _groupedSounds;
    final categoryOrder = [
      '自然',
      '雨声',
      '城市',
      '场所',
      '交通',
      '物品',
      '白噪音',
      '动物',
      '音乐',
    ];

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: categoryOrder.length,
        itemBuilder: (context, index) {
          final category = categoryOrder[index];
          final sounds = groupedSounds[category];

          if (sounds == null || sounds.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分类标题
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              // 该分类下的声音网格
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: sounds.length,
                itemBuilder: (context, soundIndex) {
                  final sound = sounds[soundIndex];
                  return SoundCard(soundAsset: sound);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _showPlayingList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PlayingListSheet(),
    );
  }
}

class SoundCard extends StatelessWidget {
  final SoundAsset soundAsset;

  const SoundCard({super.key, required this.soundAsset});

  @override
  Widget build(BuildContext context) {
    final playing = context.select<SoundManager, bool>(
      (soundManager) => soundManager.isPlaying(soundAsset),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: playing
              ? [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ]
              : [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface,
                ],
        ),
        border: Border.all(
          color: playing
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: playing
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: playing ? 8 : 4,
            offset: Offset(0, playing ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (playing) {
              SoundManager.i.stop(soundAsset);
            } else if (SoundManager.i.countMaximum()) {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.removeCurrentSnackBar();
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('已达到最大播放数')),
              );
            } else {
              SoundManager.i.play(soundAsset);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: playing
                                ? [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.7),
                                  ]
                                : [
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceVariant,
                                    Theme.of(context).colorScheme.surfaceVariant
                                        .withOpacity(0.8),
                                  ],
                          ),
                        ),
                        child: Icon(
                          soundAsset.icon,
                          size: 30,
                          color: playing
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (playing)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  soundAsset.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: playing ? FontWeight.w600 : FontWeight.w500,
                    color: playing
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  soundAsset.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayingListSheet extends StatefulWidget {
  const PlayingListSheet({super.key});

  @override
  State<PlayingListSheet> createState() => _PlayingListSheetState();
}

class _PlayingListSheetState extends State<PlayingListSheet> {
  @override
  Widget build(BuildContext context) {
    final playingSounds = context.watch<SoundManager>().playingSounds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('正在播放', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '${playingSounds.length} 个声音',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  SoundManager.i.stopAll();
                  Navigator.pop(context);
                },
                child: const Text('全部停止'),
              ),
            ],
          ),
        ),
        Expanded(
          child: playingSounds.isEmpty
              ? Center(child: Text('暂无正在播放的音频'))
              : ListView.builder(
                  itemCount: playingSounds.length,
                  itemBuilder: (context, idx) {
                    final playingSound = playingSounds[idx];
                    final soundAsset = playingSound.asset;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.audiotrack,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              soundAsset.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.stop),
                                  onPressed: () =>
                                      SoundManager.i.stop(soundAsset),
                                ),
                              ],
                            ),
                          ),
                          // 音量调节滑块
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: StatefulBuilder(
                              builder: (context, setVolumeBarState) {
                                final volume = playingSound.player.volume;
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.volume_down,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 12,
                                              ),
                                        ),
                                        child: Slider(
                                          value: volume,
                                          min: 0.0,
                                          max: 1.0,
                                          divisions: 20,
                                          onChanged: (value) {
                                            setVolumeBarState(() {
                                              playingSound.player.setVolume(
                                                value,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.volume_up,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '${(volume * 100).round()}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
