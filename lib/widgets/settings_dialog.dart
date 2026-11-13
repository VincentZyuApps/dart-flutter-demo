import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../services/app_config_service.dart';
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
  late final TextEditingController _tokenController;
  final List<TextEditingController> _sourceControllers = [];
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController(
      text: NetworkProxyService.instance.manualUrl,
    );
    _tokenController = TextEditingController(
      text: AppConfigService.instance.githubToken,
    );
    for (final src in AppConfigService.instance.sources) {
      _sourceControllers.add(TextEditingController(text: src));
    }
  }

  @override
  void dispose() {
    _proxyController.dispose();
    _tokenController.dispose();
    for (final c in _sourceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncAndSave() {
    final cfg = AppConfigService.instance;
    cfg.themeMode = themeNotifier.value;
    cfg.fontFamily = FontService.instance.currentFont;
    cfg.proxyMode = NetworkProxyService.instance.mode;
    cfg.manualProxyUrl = _proxyController.text.trim();
    cfg.enableLazerHud = showPerformanceHudNotifier.value;
    cfg.detailedLazerHud = detailedPerformanceHudNotifier.value;
    cfg.githubToken = _tokenController.text.trim();
    cfg.sources = _sourceControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (cfg.sources.isEmpty) {
      cfg.sources = List.from(AppConfigService.defaultSources);
    }
    cfg.save();
  }

  void _showTokenGuideDialog(BuildContext context) {
    final guideTokenCtrl = TextEditingController(text: _tokenController.text);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('GitHub Token 获取与提额向导'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '配置 Token 后，GitHub API 配额从 60 次/小时 直接飙升至 5,000 次/小时，彻底告别 403 / 429 速率限制报错！',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '安全承诺：本应用仅抓取公开公开仓库（Public Repos），无需勾选任何账号私有读写权限，零泄露风险。',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        const url =
                            'https://github.com/settings/tokens/new?description=DartFlutterDemo&scopes=public_repo';
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('🚀 打开 GitHub 预填生成页 (自动配好权限)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '打开后滑到页面底部，点击绿色 Generate token 并复制即可',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: guideTokenCtrl,
                    decoration: const InputDecoration(
                      labelText: '在此粘贴生成的 Token (形如 ghp_xxx)',
                      prefixIcon: Icon(Icons.content_paste_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _tokenController.text = guideTokenCtrl.text.trim();
                });
                _syncAndSave();
                Navigator.pop(ctx);
              },
              child: const Text('保存并应用'),
            ),
          ],
        );
      },
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
        width: 580,
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
                        icon: Icon(Icons.brightness_auto),
                        label: Text('跟随系统'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('浅色'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('深色'),
                      ),
                    ],
                    selected: {currentMode},
                    onSelectionChanged: (selection) {
                      setThemeMode(selection.first);
                      _syncAndSave();
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. 全局字体矩阵模块
              _buildSectionHeader(context, Icons.text_fields_rounded, '全局字体矩阵 (10 款精选字族)'),
              const SizedBox(height: 8),
              ValueListenableBuilder<AppFontFamily>(
                valueListenable: FontService.instance.currentFontNotifier,
                builder: (context, currentFont, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppFontFamily>(
                        value: currentFont,
                        isExpanded: true,
                        items: AppFontFamily.values.map((font) {
                          return DropdownMenuItem<AppFontFamily>(
                            value: font,
                            child: Row(
                              children: [
                                Text(
                                  font.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    font.category,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontSize: 10,
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
                            _syncAndSave();
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

              // 3. Firefox 三态全局代理模块
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
                          _syncAndSave();
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
                                  _syncAndSave();
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
                                _syncAndSave();
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

              // 4. 🔑 GitHub API 鉴权 Token 模块 (解决 403 限流)
              _buildSectionHeader(context, Icons.key_rounded, 'GitHub API 鉴权配置 (配额提至 5,000次/小时)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      decoration: InputDecoration(
                        labelText: 'GitHub Personal Access Token',
                        hintText: 'ghp_************************************',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureToken = !_obscureToken),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      onChanged: (_) => _syncAndSave(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => _showTokenGuideDialog(context),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('获取向导'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '未配置时限制 60次/小时，配置后提升至 5,000次/小时。仅读取公开仓库，无需私有权限。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),

              // 5. 🌐 GitHub 数据源管理模块 (持久化存盘)
              _buildSectionHeader(context, Icons.source_rounded, 'GitHub 数据源列表 (Sources 持久化)'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (int i = 0; i < _sourceControllers.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _sourceControllers[i],
                              decoration: InputDecoration(
                                isDense: true,
                                border: const OutlineInputBorder(),
                                hintText: 'https://github.com/Username?tab=repositories',
                              ),
                              onChanged: (_) => _syncAndSave(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: '删除此源',
                            onPressed: _sourceControllers.length <= 1
                                ? null
                                : () {
                                    setState(() {
                                      _sourceControllers.removeAt(i).dispose();
                                    });
                                    _syncAndSave();
                                  },
                          ),
                        ],
                      ),
                      if (i < _sourceControllers.length - 1) const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _sourceControllers.add(TextEditingController());
                            });
                            _syncAndSave();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('添加数据源'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            for (final c in _sourceControllers) {
                              c.dispose();
                            }
                            _sourceControllers.clear();
                            for (final s in AppConfigService.defaultSources) {
                              _sourceControllers.add(TextEditingController(text: s));
                            }
                            setState(() {});
                            _syncAndSave();
                          },
                          icon: const Icon(Icons.restore_rounded, size: 16),
                          label: const Text('恢复预置三大源'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 6. Lazer 实时性能指示器模块
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
                      _syncAndSave();
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
                      _syncAndSave();
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
          onPressed: () {
            _syncAndSave();
            Navigator.pop(context);
          },
          child: const Text('完成'),
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
