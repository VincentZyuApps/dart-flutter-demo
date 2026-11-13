import 'dart:math' as math;

import 'package:flutter/material.dart';

class SunflowerToggle extends StatefulWidget {
  const SunflowerToggle({
    super.key,
    required this.running,
    required this.onToggle,
    this.size = 72.0,
    this.primaryColor,
    this.badgeColor,
  });

  final bool running;
  final VoidCallback onToggle;
  final double size;
  final Color? primaryColor;
  final Color? badgeColor;

  @override
  State<SunflowerToggle> createState() => _SunflowerToggleState();
}

class _SunflowerToggleState extends State<SunflowerToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    if (widget.running) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SunflowerToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.running != oldWidget.running) {
      if (widget.running) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = widget.primaryColor ?? colorScheme.primary;
    final badgeColor = widget.badgeColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0xFF1E2838)
            : colorScheme.primaryContainer.withValues(alpha: 0.35));

    final totalSize = widget.size * 1.5;
    final ghostSize = widget.size * 1.24;

    return Semantics(
      button: true,
      label: widget.running ? '停止系统监控' : '开启系统监控',
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final progress = _animation.value;
            // 旋转 2π / 12 (即一个花瓣步进角 30°)
            final turnAngle = (2 * math.pi / 12) * progress;
            // 微动放大 1.0 -> 1.10
            final scale = 1.0 + 0.10 * progress;

            return SizedBox(
              width: totalSize,
              height: totalSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. 底层：大号暗色不规则水滴遮罩 (Fluid Backdrop)
                  Transform.rotate(
                    angle: -turnAngle * 0.4,
                    child: CustomPaint(
                      size: Size(totalSize, totalSize),
                      painter: _SunflowerPathPainter(
                        progress: progress,
                        color: badgeColor,
                        petals: 12,
                        dentDepth: 0.18,
                      ),
                    ),
                  ),

                  // 2. 中层：淡淡的浅色向日葵光环 (Ghost Sunflower Bloom)
                  // 随转动伴随 15° 相位交错，产生双层花瓣重叠与通透漫反射光晕
                  if (progress > 0.01)
                    Transform.rotate(
                      angle: turnAngle + (math.pi / 12),
                      child: Container(
                        width: ghostSize,
                        height: ghostSize,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.25 * progress),
                              blurRadius: 24.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: Size(ghostSize, ghostSize),
                          painter: _SunflowerPathPainter(
                            progress: progress,
                            color: primary.withValues(alpha: 0.22 * progress),
                            petals: 12,
                            dentDepth: 0.14,
                          ),
                        ),
                      ),
                    ),

                  // 3. 顶层：饱满圆润的 Cookie-12 曲奇向日葵主按钮
                  Transform.rotate(
                    angle: turnAngle,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35 * progress + 0.12),
                              blurRadius: 16.0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _SunflowerPathPainter(
                            progress: progress,
                            color: primary,
                            petals: 12,
                            dentDepth: 0.13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. 居中形变矢量图标 (Play ▶ <-> Pause ⏸)
                  Center(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: widget.running
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Icon(
                        Icons.play_arrow_rounded,
                        size: widget.size * 0.48,
                        color: colorScheme.onPrimary,
                      ),
                      secondChild: Icon(
                        Icons.pause_rounded,
                        size: widget.size * 0.44,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 采用严格三次贝塞尔切线平滑连接的 12 瓣圆滑曲奇向日葵 Painter
/// 波峰外凸为平滑圆弧，波谷内凹亦为平滑圆弧，彻底消除尖锐棱角
class _SunflowerPathPainter extends CustomPainter {
  const _SunflowerPathPainter({
    required this.progress,
    required this.color,
    this.petals = 12,
    this.dentDepth = 0.13,
  });

  final double progress;
  final Color color;
  final int petals;
  final double dentDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    // 当 progress=0 为正圆；随着 progress 增加，凹槽平滑加深
    final innerRadius = outerRadius * (1.0 - dentDepth * progress);

    final path = Path();
    final totalNodes = petals * 2;
    final step = (math.pi * 2) / totalNodes;

    // 收集所有关键节点坐标
    final points = <Offset>[];
    for (int i = 0; i < totalNodes; i++) {
      final angle = i * step;
      final isPeak = i.isEven;
      final r = isPeak ? outerRadius : innerRadius;
      points.add(Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      ));
    }

    // 使用三次贝塞尔曲线沿极坐标切线平滑环绕
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < totalNodes; i++) {
      final nextIdx = (i + 1) % totalNodes;
      final p0 = points[i];
      final p1 = points[nextIdx];

      final angle0 = i * step;
      final angle1 = nextIdx * step;

      // 切线正交向量，确保每个极值点处切线绝对垂直于半径 (导数一阶连续平滑，完全无折角)
      final t0 = Offset(-math.sin(angle0), math.cos(angle0));
      final t1 = Offset(-math.sin(angle1), math.cos(angle1));

      final dist = (p1 - p0).distance * 0.36;

      final c0 = p0 + t0 * dist;
      final c1 = p1 - t1 * dist;

      path.cubicTo(c0.dx, c0.dy, c1.dx, c1.dy, p1.dx, p1.dy);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SunflowerPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.dentDepth != dentDepth;
  }
}
