import 'dart:io';
import 'package:flutter/foundation.dart';

enum ProxyMode {
  direct,
  system,
  manual,
}

class NetworkProxyService {
  NetworkProxyService._() {
    applyCurrentProxy();
  }

  static final NetworkProxyService instance = NetworkProxyService._();

  static const String defaultManualProxy = 'http://127.0.0.1:7890';

  final ValueNotifier<ProxyMode> modeNotifier =
      ValueNotifier<ProxyMode>(ProxyMode.system);
  final ValueNotifier<String> manualUrlNotifier =
      ValueNotifier<String>(defaultManualProxy);

  ProxyMode get mode => modeNotifier.value;
  String get manualUrl => manualUrlNotifier.value;

  String get summary {
    switch (mode) {
      case ProxyMode.direct:
        return '直连模式';
      case ProxyMode.system:
        return '系统代理';
      case ProxyMode.manual:
        return '手动代理 ($manualUrl)';
    }
  }

  void setMode(ProxyMode newMode) {
    if (modeNotifier.value == newMode) return;
    modeNotifier.value = newMode;
    applyCurrentProxy();
  }

  void setManualUrl(String url) {
    final trimmed = url.trim();
    if (manualUrlNotifier.value == trimmed) return;
    manualUrlNotifier.value = trimmed;
    if (modeNotifier.value == ProxyMode.manual) {
      applyCurrentProxy();
    }
  }

  void applyCurrentProxy() {
    HttpOverrides.global = AppHttpOverrides(
      mode: modeNotifier.value,
      proxyUrl: manualUrlNotifier.value,
    );
  }
}

class AppHttpOverrides extends HttpOverrides {
  AppHttpOverrides({
    required this.mode,
    required this.proxyUrl,
  });

  final ProxyMode mode;
  final String proxyUrl;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    switch (mode) {
      case ProxyMode.direct:
        client.findProxy = (uri) => 'DIRECT';
        break;

      case ProxyMode.system:
        // 系统默认行为
        break;

      case ProxyMode.manual:
        if (proxyUrl.isNotEmpty) {
          final uri = Uri.tryParse(proxyUrl);
          final host =
              (uri != null && uri.host.isNotEmpty) ? uri.host : '127.0.0.1';
          final port = (uri != null && uri.port > 0) ? uri.port : 7890;
          client.findProxy = (requestUri) => 'PROXY $host:$port; DIRECT';
        }
        break;
    }

    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}
