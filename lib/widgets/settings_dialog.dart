import 'package:flutter/material.dart';

import '../app.dart';
import '../services/app_performance.dart';
import '../services/font_service.dart';
import '../services/network_proxy_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _proxyController;

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController(
      text: NetworkProxyService.instance.manualUrl,
    );
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
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
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 外观主题模块
              _buildSectionHeader(context, Icons.palette_outlined, '外观与主题'),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),

              // 2. 全局字体矩阵 (真实落地)
              _buildSectionHeader(context, Icons.text_fields_rounded, '全局字体字族切换 (10 款精选)'),
              const SizedBox(height: 8),
              ValueListenableBuilder<AppFontFamily>(
                valueListenable: FontService.instance.currentFontNotifier,
                builder: (context, currentFont, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppFontFamily>(
                        value: currentFont,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: AppFontFamily.values.map((font) {
                          return DropdownMenuItem<AppFontFamily>(
                            value: font,
                            child: Row(
                              children: [
                                Text(
                                  font.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    font.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newFont) {
                          if (newFont != null) {
                            FontService.instance.setFont(newFont);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<AppFontFamily>(
                valueListenable: FontService.instance.currentFontNotifier,
                builder: (context, currentFont, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '当前字族说明: ${currentFont.description}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Firefox 三态全局代理模块 (真实落地)
              _buildSectionHeader(context, Icons.vpn_lock_rounded, '全局网络代理设置 (Firefox 经典三态)'),
              const SizedBox(height: 8),
              ValueListenableBuilder<ProxyMode>(
                valueListenable: NetworkProxyService.instance.modeNotifier,
                builder: (context, mode, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<ProxyMode>(
                        segments: const [
                          ButtonSegment(
                            value: ProxyMode.direct,
                            icon: Icon(Icons.flash_on_rounded),
                            label: Text('直连'),
                          ),
                          ButtonSegment(
                            value: ProxyMode.system,
                            icon: Icon(Icons.settings_suggest_rounded),
                            label: Text('系统代理'),
                          ),
                          ButtonSegment(
                            value: ProxyMode.manual,
                            icon: Icon(Icons.lan_rounded),
                            label: Text('手动代理'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (selection) {
                          NetworkProxyService.instance.setMode(selection.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          switch (mode) {
                            ProxyMode.direct => '模式说明: 所有网络请求直接连接互联网 (DIRECT)',
                            ProxyMode.system => '模式说明: 跟随操作系统当前配置的系统代理环境',
                            ProxyMode.manual => '模式说明: 指定本地/局域网代理地址，全局接管 HTTP 请求',
                          },
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (mode == ProxyMode.manual) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _proxyController,
                                decoration: InputDecoration(
                                  labelText: 'HTTP 代理地址',
                                  hintText: 'http://127.0.0.1:7890',
                                  prefixIcon: const Icon(Icons.link_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  NetworkProxyService.instance.setManualUrl(val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                _proxyController.text = NetworkProxyService.defaultManualProxy;
                                NetworkProxyService.instance.setManualUrl(
                                  NetworkProxyService.defaultManualProxy,
                                );
                              },
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('默认'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 4. Lazer 实时性能指示器模块
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
                    dense: true,
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
                    dense: true,
                  );
                },
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
