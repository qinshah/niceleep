import 'package:flutter/material.dart';
import 'package:niceleep/app/constant.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:niceleep/app/state_mgmt/sound_manager.dart';
import 'package:niceleep/settings/state_mgmt/theme_cntlr.dart';
import 'package:provider/provider.dart';
import 'theme_page_view.dart';

class SettingsPageView extends StatefulWidget {
  const SettingsPageView({super.key});

  @override
  State<SettingsPageView> createState() => _SettingsPageViewState();
}

class _SettingsPageViewState extends State<SettingsPageView> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('外观'),
          _buildThemeTile(context),
          const SizedBox(height: 24),

          _buildSectionHeader('声音'),
          // _buildListTile(
          //   icon: Icons.language,
          //   title: '语言',
          //   subtitle: '简体中文',
          //   onTap: () => _showLanguageSelectionDialog(context),
          // ),
          _buildVolumeTile(context),
          Builder(
            builder: (context) {
              final maxSoundCount = context.select<SoundManager, int>(
                (manager) => manager.maxSoundCount,
              );
              return _buildListTile(
                title: '最大音频数',
                icon: Icons.queue_music, // 更换为表示数量/队列的图标
                subtitle: '$maxSoundCount个',
                onTap: () {
                  _showMaxSoundCountDialog(context, maxSoundCount);
                },
              );
            },
          ),

          SizedBox(height: 50),

          _buildSectionHeader('其他'),
          // _buildListTile(
          //   icon: Icons.description,
          //   title: '用户协议',
          //   onTap: () => _launchUrl('https://example.com/terms'),
          // ),
          // _buildListTile(
          //   title: '反馈',
          //   icon: Icons.feedback_outlined,
          //   onTap: () => _launchUrl(Constant.issues),
          // ),

          // 仅商店版显示隐私政策
          if (Constant.isStoreVersion)
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: '隐私政策',
              onTap: () => _launchUrl(Constant.privacy),
            ),

          _buildListTile(
            title: 'Source Code',
            icon: Icons.code,
            onTap: () => _launchUrl(Constant.github),
          ),
          SizedBox(height: 16),
          Center(
            child: Text('版本:$_version', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    return Consumer<ThemeCntlr>(
      builder: (context, themeCntlr, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.palette,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              '主题模式',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _getThemeModeText(themeCntlr.themeMode),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemePageView()),
              );
            },
          ),
        );
      },
    );
  }

  // Widget _buildSwitchTile({
  //   required IconData icon,
  //   required String title,
  //   required String subtitle,
  //   required bool value,
  //   required ValueChanged<bool> onChanged,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 4),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surface,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
  //       ),
  //     ),
  //     child: ListTile(
  //       leading: Icon(
  //         icon,
  //         color: Theme.of(context).colorScheme.onSurfaceVariant,
  //       ),
  //       title: Text(
  //         title,
  //         style: TextStyle(
  //           color: Theme.of(context).colorScheme.onSurface,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       subtitle: Text(
  //         subtitle,
  //         style: TextStyle(
  //           color: Theme.of(context).colorScheme.onSurfaceVariant,
  //         ),
  //       ),
  //       trailing: Switch(
  //         value: value,
  //         onChanged: onChanged,
  //         activeThumbColor: Theme.of(context).colorScheme.primary,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildVolumeTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.volume_up,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          '统一调整音量',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '调整所有正在播放的音频音量',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showVolumeAdjustDialog(context),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  // void _showLanguageSelectionDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('选择语言'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             ListTile(
  //               leading: const Icon(Icons.language),
  //               title: const Text('简体中文'),
  //               trailing: const Icon(Icons.check, color: Colors.blue),
  //               onTap: () {
  //                 Navigator.pop(context);
  //               },
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('确定'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showVolumeAdjustDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        double volume = 0.5;
        return AlertDialog(
          title: const Text('调整所有音量'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('应用到所有正在播放的声音'),
                  const SizedBox(height: 16),
                  Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) {
                      setDialogState(() => volume = value);
                      // 实时更新全局音量
                      SoundManager.i.setAllVolume(value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('0%'),
                      Text('${(volume * 100).round()}%'),
                      const Text('100%'),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showMaxSoundCountDialog(BuildContext context, int currentCount) {
    int selectedCount = currentCount;
    final min = 5;
    final max = 20;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('最大音频数'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('同时播放的音频数量上限'),
                  const Text('过多音频同时播放会导致卡顿'),
                  const SizedBox(height: 16),
                  Slider(
                    value: selectedCount.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    label: selectedCount.toString(),
                    onChanged: (value) {
                      setDialogState(() => selectedCount = value.toInt());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(min.toString()),
                      Text('$selectedCount个'),
                      Text(max.toString()),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final success = await SoundManager.i.setMaxSoundCount(
                  selectedCount,
                );
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    // 显示成功提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('最大音频数已设置为 $selectedCount 个'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('设置失败'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
