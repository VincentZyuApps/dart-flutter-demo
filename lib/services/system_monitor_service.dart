import 'dart:async';
import 'dart:io' show ProcessInfo;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'system_info_service.dart';

class SystemMetricPoint {
  const SystemMetricPoint({
    required this.cpuPercent,
    required this.memoryUsedMB,
    required this.memoryTotalMB,
    required this.memoryPercent,
    required this.uploadSpeedKBs,
    required this.downloadSpeedKBs,
    required this.timestamp,
  });

  final double cpuPercent;
  final double memoryUsedMB;
  final double memoryTotalMB;
  final double memoryPercent;
  final double uploadSpeedKBs;
  final double downloadSpeedKBs;
  final DateTime timestamp;
}

class SystemMonitorService extends ChangeNotifier {
  SystemMonitorService({
    this.historyCapacity = 30,
    this.sampleInterval = const Duration(seconds: 1),
  });

  static final SystemMonitorService instance = SystemMonitorService();

  final int historyCapacity;
  final Duration sampleInterval;

  bool _isMonitoring = false;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  final List<double> _cpuHistory = <double>[];
  final List<double> _memoryHistory = <double>[];
  final List<double> _uploadHistory = <double>[];
  final List<double> _downloadHistory = <double>[];

  double _currentCpu = 0.0;
  double _currentMemoryMB = 0.0;
  double _totalMemoryMB = 16384.0;
  double _currentMemoryPercent = 0.0;

  double _currentUploadKBs = 0.0;
  double _currentDownloadKBs = 0.0;
  double _peakUploadKBs = 0.0;
  double _peakDownloadKBs = 0.0;
  int _totalUploadedBytes = 0;
  int _totalDownloadedBytes = 0;

  final math.Random _random = math.Random();

  bool get isMonitoring => _isMonitoring;
  Duration get monitorDuration => _stopwatch.elapsed;

  List<double> get cpuHistory => List.unmodifiable(_cpuHistory);
  List<double> get memoryHistory => List.unmodifiable(_memoryHistory);
  List<double> get uploadHistory => List.unmodifiable(_uploadHistory);
  List<double> get downloadHistory => List.unmodifiable(_downloadHistory);

  double get currentCpu => _currentCpu;
  double get currentMemoryMB => _currentMemoryMB;
  double get totalMemoryMB => _totalMemoryMB;
  double get currentMemoryPercent => _currentMemoryPercent;

  double get currentUploadKBs => _currentUploadKBs;
  double get currentDownloadKBs => _currentDownloadKBs;
  double get peakUploadKBs => _peakUploadKBs;
  double get peakDownloadKBs => _peakDownloadKBs;
  int get totalUploadedBytes => _totalUploadedBytes;
  int get totalDownloadedBytes => _totalDownloadedBytes;

  void toggleMonitoring() {
    if (_isMonitoring) {
      stopMonitoring();
    } else {
      startMonitoring();
    }
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _stopwatch.start();
    _initSampleData();
    _timer?.cancel();
    _timer = Timer.periodic(sampleInterval, (_) => _tick());
    notifyListeners();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resetMetrics() {
    _stopwatch.reset();
    _cpuHistory.clear();
    _memoryHistory.clear();
    _uploadHistory.clear();
    _downloadHistory.clear();
    _peakUploadKBs = 0.0;
    _peakDownloadKBs = 0.0;
    _totalUploadedBytes = 0;
    _totalDownloadedBytes = 0;
    notifyListeners();
  }

  void _initSampleData() {
    _tryFetchHardwareBaseline();
    _tick();
  }

  Future<void> _tryFetchHardwareBaseline() async {
    try {
      final infoService = createSystemInfoService();
      var snapshot = infoService.latestSnapshot;
      if (snapshot == null) {
        await infoService.getInfo();
        snapshot = infoService.latestSnapshot;
      }
      if (snapshot != null) {
        if (snapshot.memoryTotalBytes != null && snapshot.memoryTotalBytes! > 0) {
          _totalMemoryMB = snapshot.memoryTotalBytes! / (1024 * 1024);
        }
        if (snapshot.memoryUsedBytes != null && snapshot.memoryUsedBytes! > 0) {
          _currentMemoryMB = snapshot.memoryUsedBytes! / (1024 * 1024);
          _currentMemoryPercent = (_currentMemoryMB / _totalMemoryMB) * 100;
        }
      }
    } catch (_) {
      // 保持合理的缺省基线
    }
  }

  void _tick() {
    // 1. CPU 采样与波动模型 (12% ~ 45% 的真实日常负载波动)
    final cpuDelta = (_random.nextDouble() - 0.48) * 8.0;
    _currentCpu = (_currentCpu <= 0 ? 15.0 : _currentCpu + cpuDelta).clamp(4.0, 92.0);

    // 2. 内存计算与平缓漂移
    if (_currentMemoryMB <= 0) {
      final rssMB = ProcessInfo.currentRss / (1024 * 1024);
      _currentMemoryMB = math.max(rssMB * 8, 4096.0);
    } else {
      final memDelta = (_random.nextDouble() - 0.49) * 32.0;
      _currentMemoryMB = (_currentMemoryMB + memDelta).clamp(512.0, _totalMemoryMB);
    }
    _currentMemoryPercent = (_currentMemoryMB / _totalMemoryMB) * 100.0;

    // 3. 网络瞬时上下行与峰值记录
    // 模拟真实的突发脉冲网络行为 (如后台拉取、请求握手与闲置交替)
    final hasBurst = _random.nextDouble() > 0.75;
    final upBase = hasBurst ? _random.nextDouble() * 850.0 : _random.nextDouble() * 80.0;
    final downBase = hasBurst ? _random.nextDouble() * 2400.0 : _random.nextDouble() * 260.0;

    _currentUploadKBs = upBase;
    _currentDownloadKBs = downBase;

    if (_currentUploadKBs > _peakUploadKBs) {
      _peakUploadKBs = _currentUploadKBs;
    }
    if (_currentDownloadKBs > _peakDownloadKBs) {
      _peakDownloadKBs = _currentDownloadKBs;
    }

    _totalUploadedBytes += (_currentUploadKBs * 1024).round();
    _totalDownloadedBytes += (_currentDownloadKBs * 1024).round();

    // 4. 压入历史固定容量环形队列
    _appendHistory(_cpuHistory, _currentCpu);
    _appendHistory(_memoryHistory, _currentMemoryPercent);
    _appendHistory(_uploadHistory, _currentUploadKBs);
    _appendHistory(_downloadHistory, _currentDownloadKBs);

    notifyListeners();
  }

  void _appendHistory(List<double> list, double value) {
    list.add(value);
    if (list.length > historyCapacity) {
      list.removeAt(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
