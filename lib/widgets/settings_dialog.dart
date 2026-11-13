import 'package:flutter/material.dart';

import '../app.dart';
import '../services/app_performance.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('全局设置 (Settings)'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 外观主题模块
              _buildSectionHeader(context, Icons.palette_outlined, '外观与主题'),
              const SizedBox(height: 6),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, currentMode, _) {
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.desktop_windows_outlined),
                        label: Text('跟随系统'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.wb_sunny_outlined),
                        label: Text('浅色'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.nightlight_round),
                        label: Text('深色'),
                      ),
                    ],
                    selected: {currentMode},
                    onSelectionChanged: (newSet) {
                      setThemeMode(newSet.first);
                    },
                  );
                },
              ),
              const SizedBox(height: 18),

              // 2. Lazer 实时性能指示器模块
              _buildSectionHeader(context, Icons.speed_rounded, 'Lazer 实时性能 HUD 胶囊'),
              const SizedBox(height: 6),
              ValueListenableBuilder<bool>(
                valueListenable: showPerformanceHudNotifier,
                builder: (context, isShown, _) {
                  return SwitchListTile(
                    title: const Text('显示实时渲染性能胶囊'),
                    subtitle: const Text('基于 SchedulerBinding 监测 UI、GPU、低帧与帧预算'),
                    value: isShown,
                    onChanged: (val) {
                      showPerformanceHudNotifier.value = val;
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              ValueListenableBuilder<bool>(
                valueListenable: detailedPerformanceHudNotifier,
                builder: (context, isDetailed, _) {
                  return SwitchListTile(
                    title: const Text('详细性能模式 (Lazer Style)'),
                    subtitle: const Text('完整展示 UI 耗时、GPU 耗时、10ms 预算与峰值'),
                    value: isDetailed,
                    onChanged: (val) {
                      detailedPerformanceHudNotifier.value = val;
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 3. 全局多字族体系规划预告
              _buildSectionHeader(context, Icons.text_fields_rounded, '全局字体矩阵 (规划中)'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '0.6.x 将收拢 10 款精选字族：LXGW 独立包、MiSans 内置、Noto Sans、JetBrains Mono、Fira Code、Poppins 等，支持在设置中实时全局切换。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Firefox 三态全局代理预告
              _buildSectionHeader(context, Icons.vpn_lock_rounded, '全局网络代理 (规划中)'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '0.6.x 将提供类似 Firefox 的经典三态单选配置：① 直连 / ② 系统代理 / ③ 指定代理 (默认 127.0.0.1:7890)，并自动移除 Page 3 冗余输入框。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
