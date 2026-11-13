import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/system_monitor_service.dart';
import 'smooth_wave_chart.dart';
import 'sunflower_toggle.dart';

class SystemMonitorDashboard extends StatefulWidget {
  const SystemMonitorDashboard({
    super.key,
    this.hostInfo,
    this.osInfo,
  });

  final String? hostInfo;
  final String? osInfo;

  @override
  State<SystemMonitorDashboard> createState() => _SystemMonitorDashboardState();
}

class _SystemMonitorDashboardState extends State<SystemMonitorDashboard> {
  final _service = SystemMonitorService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatSpeed(double kbs) {
    if (kbs >= 1024.0) {
      return '${(kbs / 1024.0).toStringAsFixed(1)} MB/s';
    }
    return '${kbs.toStringAsFixed(1)} KB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF181C24)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colorScheme.outlineVariant.withValues(alpha: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 方案一主控卡片 (Master Card) - 包含 Sunflower 向日葵按钮与系统总体状态
            _buildMasterCard(context, cardBg, cardBorder, isNarrow),
            const SizedBox(height: 12),

            // 2. 四宫格指标卡片 (宽屏 2x2 / 窄屏 1x4)
            if (isNarrow)
              Column(
                children: [
                  _buildCpuCard(context, cardBg, cardBorder),
                  const SizedBox(height: 10),
                  _buildMemoryCard(context, cardBg, cardBorder),
                  const SizedBox(height: 10),
                  _buildUploadCard(context, cardBg, cardBorder),
                  const SizedBox(height: 10),
                  _buildDownloadCard(context, cardBg, cardBorder),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildCpuCard(context, cardBg, cardBorder)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMemoryCard(context, cardBg, cardBorder)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildUploadCard(context, cardBg, cardBorder)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDownloadCard(context, cardBg, cardBorder)),
                    ],
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildMasterCard(
    BuildContext context,
    Color bg,
    Color border,
    bool isNarrow,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final isRunning = _service.isMonitoring;

    // 未运行状态为纯暗中性灰色；运行中平滑渐变到带有 12% 品牌色的微光深色
    final inactiveTone = theme.brightness == Brightness.dark
        ? const Color(0xFF22242B)
        : const Color(0xFFE5E7EB);
    final activeTone = Color.alphaBlend(
      primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.14 : 0.10),
      bg,
    );

    final decorSize = isNarrow ? 138.0 : 165.0;
    final decorEnd = isNarrow ? -24.0 : -32.0;
    final decorTop = isNarrow ? -28.0 : -38.0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. 底层：紧凑偏心向日葵背景波浪 (Eccentric Fluid Backdrop)
          PositionedDirectional(
            end: decorEnd,
            top: decorTop,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: isRunning ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, progress, _) {
                final decorColor = Color.lerp(inactiveTone, activeTone, progress)!;
                final decorTurn = (2 * math.pi / 12) * progress;
                final decorScale = 1.0 + 0.05 * progress;

                return Transform.rotate(
                  angle: -decorTurn * 0.5,
                  child: Transform.scale(
                    scale: decorScale,
                    child: CustomPaint(
                      size: Size(decorSize, decorSize),
                      painter: SunflowerPathPainter(
                        progress: 1.0,
                        color: decorColor,
                        petals: 12,
                        dentDepth: 0.16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. 顶层内容：左侧信息 + 右侧 SunflowerToggle 按钮
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 20,
              vertical: isNarrow ? 14 : 18,
            ),
            child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧系统概要与运行状态
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRunning ? const Color(0xFF10B981) : Colors.grey,
                        boxShadow: isRunning
                            ? [
                                const BoxShadow(
                                  color: Color(0xFF10B981),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRunning ? '实时监视中' : '监视已待机',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isRunning
                            ? const Color(0xFF10B981)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '周期 1.0s',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.osInfo ?? '跨平台系统环境',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '已监控: ${_formatDuration(_service.monitorDuration)} · 设备: ${widget.hostInfo ?? 'LocalHost'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 右侧核心 Sunflower 12 瓣向日葵形变按钮
          SunflowerToggle(
            running: isRunning,
            onToggle: () {
              _service.toggleMonitoring();
            },
            size: isNarrow ? 58.0 : 68.0,
          ),
        ],
      ),
    ),
  ],
),
);
  }

  Widget _buildMetricCardContainer({
    required BuildContext context,
    required Color bg,
    required Color border,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required List<double> values,
    required double minScale,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          SmoothWaveChart(
            values: values,
            color: accentColor,
            minScale: minScale,
            height: 62.0,
          ),
        ],
      ),
    );
  }

  Widget _buildCpuCard(BuildContext context, Color bg, Color border) {
    final cpu = _service.currentCpu;
    return _buildMetricCardContainer(
      context: context,
      bg: bg,
      border: border,
      icon: Icons.memory_rounded,
      title: 'CPU 负载',
      value: '${cpu.toStringAsFixed(1)} %',
      subtitle: '多核并行计算\n实时波动',
      accentColor: const Color(0xFF8B5CF6), // 紫色
      values: _service.cpuHistory,
      minScale: 100.0,
    );
  }

  Widget _buildMemoryCard(BuildContext context, Color bg, Color border) {
    final memUsedGB = _service.currentMemoryMB / 1024.0;
    final memTotalGB = _service.totalMemoryMB / 1024.0;
    final percent = _service.currentMemoryPercent;

    return _buildMetricCardContainer(
      context: context,
      bg: bg,
      border: border,
      icon: Icons.storage_rounded,
      title: '物理内存',
      value: '${memUsedGB.toStringAsFixed(1)} GB',
      subtitle: '总量 ${memTotalGB.toStringAsFixed(1)} GB\n占比 ${percent.toStringAsFixed(1)}%',
      accentColor: const Color(0xFF06B6D4), // 青蓝
      values: _service.memoryHistory,
      minScale: 100.0,
    );
  }

  Widget _buildUploadCard(BuildContext context, Color bg, Color border) {
    final upSpeed = _service.currentUploadKBs;
    final peak = _service.peakUploadKBs;
    final total = _service.totalUploadedBytes;

    return _buildMetricCardContainer(
      context: context,
      bg: bg,
      border: border,
      icon: Icons.arrow_upward_rounded,
      title: '网络上行',
      value: _formatSpeed(upSpeed),
      subtitle: '峰值 ${_formatSpeed(peak)}\n累计 ${_formatBytes(total)}',
      accentColor: const Color(0xFFF59E0B), // 橙金
      values: _service.uploadHistory,
      minScale: 200.0,
    );
  }

  Widget _buildDownloadCard(BuildContext context, Color bg, Color border) {
    final downSpeed = _service.currentDownloadKBs;
    final peak = _service.peakDownloadKBs;
    final total = _service.totalDownloadedBytes;

    return _buildMetricCardContainer(
      context: context,
      bg: bg,
      border: border,
      icon: Icons.arrow_downward_rounded,
      title: '网络下行',
      value: _formatSpeed(downSpeed),
      subtitle: '峰值 ${_formatSpeed(peak)}\n累计 ${_formatBytes(total)}',
      accentColor: const Color(0xFF3B82F6), // 主蓝
      values: _service.downloadHistory,
      minScale: 500.0,
    );
  }
}
