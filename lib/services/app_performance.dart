import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

final ValueNotifier<int> shellRebuildCountNotifier = ValueNotifier<int>(0);
final ValueNotifier<double> frameFpsNotifier = ValueNotifier<double>(0);
final ValueNotifier<double> frameLowFpsNotifier = ValueNotifier<double>(0);
final ValueNotifier<double> frameUiMsNotifier = ValueNotifier<double>(0);
final ValueNotifier<double> frameGpuMsNotifier = ValueNotifier<double>(0);
final ValueNotifier<double> frameWorstMsNotifier = ValueNotifier<double>(0);

final ValueNotifier<bool> showPerformanceHudNotifier = ValueNotifier<bool>(true);
final ValueNotifier<bool> detailedPerformanceHudNotifier = ValueNotifier<bool>(true);

class FrameFpsTracker {
  static const int _maxFrames = 150;
  final List<FrameTiming> _frames = [];
  final List<int> _frameTimestampsMicros = [];

  double _fps = 0;
  double _lowFps = 0;
  double _uiMs = 0;
  double _gpuMs = 0;
  double _worstMs = 0;

  double get fps => _fps;
  double get lowFps => _lowFps;
  double get uiMs => _uiMs;
  double get gpuMs => _gpuMs;
  double get worstMs => _worstMs;

  void addTimings(List<FrameTiming> timings) {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    for (final timing in timings) {
      _frames.add(timing);
      _frameTimestampsMicros.add(nowMicros);
    }

    if (_frames.length > _maxFrames) {
      _frames.removeRange(0, _frames.length - _maxFrames);
    }
    if (_frameTimestampsMicros.length > _maxFrames) {
      _frameTimestampsMicros.removeRange(0, _frameTimestampsMicros.length - _maxFrames);
    }

    final cutoff = nowMicros - const Duration(seconds: 1).inMicroseconds;
    _frameTimestampsMicros.removeWhere((value) => value < cutoff);

    if (_frameTimestampsMicros.isEmpty) {
      _fps = 0;
      _lowFps = 0;
      _uiMs = 0;
      _gpuMs = 0;
      _worstMs = 0;
      _notifyAll();
      return;
    }

    _fps = _frameTimestampsMicros.length.toDouble();

    // 1. UI (buildMs) 与 GPU (rasterMs) 均值
    double totalUi = 0;
    double totalGpu = 0;
    double maxSpan = 0;

    for (final frame in _frames) {
      final ui = frame.buildDuration.inMicroseconds / 1000.0;
      final gpu = frame.rasterDuration.inMicroseconds / 1000.0;
      final total = frame.totalSpan.inMicroseconds / 1000.0;

      totalUi += ui;
      totalGpu += gpu;
      if (total > maxSpan) maxSpan = total;
    }

    _uiMs = _frames.isNotEmpty ? totalUi / _frames.length : 0;
    _gpuMs = _frames.isNotEmpty ? totalGpu / _frames.length : 0;
    _worstMs = maxSpan;

    // 2. 第 5 百分位低帧 (lowFps)
    if (_frames.length >= 3) {
      final List<int> intervals = [];
      for (int i = 1; i < _frames.length; i++) {
        final span = _frames[i].timestampInMicroseconds(ui.FramePhase.vsyncStart) -
            _frames[i - 1].timestampInMicroseconds(ui.FramePhase.vsyncStart);
        if (span > 0) intervals.add(span);
      }
      if (intervals.isNotEmpty) {
        intervals.sort();
        final int p95 = intervals[((intervals.length - 1) * 0.95).ceil()];
        _lowFps = p95 > 0 ? (1000000.0 / p95).clamp(0.0, 360.0) : 0;
      }
    } else {
      _lowFps = _fps;
    }

    _notifyAll();
  }

  void _notifyAll() {
    frameFpsNotifier.value = _fps;
    frameLowFpsNotifier.value = _lowFps;
    frameUiMsNotifier.value = _uiMs;
    frameGpuMsNotifier.value = _gpuMs;
    frameWorstMsNotifier.value = _worstMs;
  }
}
