import 'package:flutter/material.dart';
import 'package:niceleep/settings/state_mgmt/theme_cntlr.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';

class ThemePageView extends StatefulWidget {
  const ThemePageView({super.key});

  @override
  State<ThemePageView> createState() => _ThemePageViewState();
}

class _ThemePageViewState extends State<ThemePageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题与色彩'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<ThemeCntlr>(
        builder: (context, themeCntlr, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('外观模式'),
              _buildThemeModeSelector(themeCntlr),
              const SizedBox(height: 24),

              _buildSectionHeader('主题设置'),
              _buildBlackBackgroundSwitch(themeCntlr),
              const SizedBox(height: 24),

              _buildSectionHeader('调色板'),
              _buildColorPalette(themeCntlr),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
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

  Widget _buildThemeModeSelector(ThemeCntlr themeCntlr) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: _buildThemeOption(
              themeCntlr,
              ThemeMode.light,
              '浅色模式',
              Icons.light_mode,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildThemeOption(
              themeCntlr,
              ThemeMode.dark,
              '深色模式',
              Icons.dark_mode,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildThemeOption(
              themeCntlr,
              ThemeMode.system,
              '跟随系统',
              Icons.brightness_auto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeCntlr themeCntlr,
    ThemeMode mode,
    String title,
    IconData icon,
  ) {
    final isSelected = themeCntlr.themeMode == mode;
    return GestureDetector(
      onTap: () => themeCntlr.setThemeMode(mode),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlackBackgroundSwitch(ThemeCntlr themeCntlr) {
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
          Icons.contrast,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          '高对比度',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '在深色模式下使用纯黑背景',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Switch(
          value: themeCntlr.useBlackBackground,
          onChanged: (value) => themeCntlr.setUseBlackBackground(value),
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildColorPalette(ThemeCntlr themeCntlr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择主题色',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 16,
            children: ThemeColor.values.map((themeColor) {
              final color = themeColor.value;
              final isSelected = themeCntlr.seedColor == color;
              return GestureDetector(
                onTap: () => themeCntlr.setSeedColor(color),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        themeColor.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 10,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Color _getContrastColor(Color color) {
  //   // 计算颜色亮度，返回对比色
  //   final luminance = color.computeLuminance();
  //   return luminance > 0.5 ? Colors.black : Colors.white;
  // }
}
