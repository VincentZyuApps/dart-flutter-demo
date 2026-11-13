import 'package:flutter/material.dart';

class SmoothWaveChart extends StatelessWidget {
  const SmoothWaveChart({
    super.key,
    required this.values,
    required this.color,
    this.minScale = 100.0,
    this.strokeWidth = 2.0,
    this.fillOpacity = 0.22,
    this.height = 68.0,
  });

  final List<double> values;
  final Color color;
  final double minScale;
  final double strokeWidth;
  final double fillOpacity;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SmoothWavePainter(
            values: values,
            color: color,
            minScale: minScale,
            strokeWidth: strokeWidth,
            fillOpacity: fillOpacity,
          ),
        ),
      ),
    );
  }
}

class _SmoothWavePainter extends CustomPainter {
  const _SmoothWavePainter({
    required this.values,
    required this.color,
    required this.minScale,
    required this.strokeWidth,
    required this.fillOpacity,
  });

  final List<double> values;
  final Color color;
  final double minScale;
  final double strokeWidth;
  final double fillOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 当暂无数据时，绘制平缓底线
    if (values.isEmpty) {
      final idlePaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, h - 2), Offset(w, h - 2), idlePaint);
      return;
    }

    // 动态计算 Y 轴最大刻度 (确保波峰有呼吸空间)
    double maxVal = minScale;
    for (final v in values) {
      if (v > maxVal) maxVal = v;
    }
    // 留出 15% 顶部裕度
    maxVal = maxVal * 1.15;

    final pointCount = values.length;
    final dx = pointCount > 1 ? w / (pointCount - 1) : w;

    final points = <Offset>[];
    for (int i = 0; i < pointCount; i++) {
      final norm = (values[i] / maxVal).clamp(0.0, 1.0);
      // y 轴翻转，下边缘为 0
      final y = h - (norm * (h - strokeWidth * 2)) - strokeWidth;
      final x = pointCount == 1 ? w / 2 : i * dx;
      points.add(Offset(x, y));
    }

    // 构建三次贝塞尔波浪曲线 (Cubic Bezier Path)
    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      strokePath.cubicTo(
        controlX,
        p0.dy,
        controlX,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    // 1. 绘制向下闭合的垂直渐变流体填充 (Fill)
    final fillPath = Path.from(strokePath);
    fillPath.lineTo(points.last.dx, h);
    fillPath.lineTo(points.first.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: fillOpacity),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. 绘制顶部高亮平滑曲线 (Stroke)
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(_SmoothWavePainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.minScale != minScale ||
        oldDelegate.values.length != values.length) {
      return true;
    }
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
