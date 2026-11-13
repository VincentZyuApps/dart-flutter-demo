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

    return Semantics(
      button: true,
      label: widget.running ? '停止系统监控' : '开启系统监控',
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final progress = _animation.value;
            // 旋转 2π / 12 (即一个完整花瓣步进角 30°)
            final turnAngle = (2 * math.pi / 12) * progress;
            // 微动放大 1.0 -> 1.10
            final scale = 1.0 + 0.10 * progress;

            return SizedBox(
              width: totalSize,
              height: totalSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. 背后大号深色/半透明同心水滴光晕 (ShapeBadge)
                  Transform.rotate(
                    angle: -turnAngle * 0.5,
                    child: CustomPaint(
                      size: Size(totalSize, totalSize),
                      painter: _SunflowerPathPainter(
                        progress: progress,
                        color: badgeColor,
                        petals: 12,
                        dentDepth: 0.18,
                        isShadowBadge: true,
                      ),
                    ),
                  ),

                  // 2. Sunflower 主体向日葵按钮 (M3 Expressive Cookie-12)
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
                              color: primary.withValues(alpha: 0.28 * progress + 0.12),
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
                            dentDepth: 0.14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. 居中形变矢量图标 (Play ▶ <-> Pause ⏸)
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

/// 采用三次贝塞尔平滑连接的 12 瓣向日葵几何图形 Painter
class _SunflowerPathPainter extends CustomPainter {
  const _SunflowerPathPainter({
    required this.progress,
    required this.color,
    this.petals = 12,
    this.dentDepth = 0.14,
    this.isShadowBadge = false,
  });

  final double progress;
  final Color color;
  final int petals;
  final double dentDepth;
  final bool isShadowBadge;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    // 当 progress=0 为正圆；随着 progress 增加，凹槽逐渐加深到 dentDepth
    final innerRadius = outerRadius * (1.0 - dentDepth * progress);

    final path = Path();
    final step = (math.pi * 2) / (petals * 2);

    for (int i = 0; i < petals * 2; i++) {
      final angle = i * step;
      final isPeak = i.isEven;
      final r = isPeak ? outerRadius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // 使用平滑贝塞尔连接
        final prevAngle = (i - 1) * step;
        final prevR = (i - 1).isEven ? outerRadius : innerRadius;
        final midAngle = (prevAngle + angle) / 2;
        final midR = (prevR + r) / 2;

        final cx = center.dx + midR * math.cos(midAngle);
        final cy = center.dy + midR * math.sin(midAngle);

        path.quadraticBezierTo(cx, cy, x, y);
      }
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
