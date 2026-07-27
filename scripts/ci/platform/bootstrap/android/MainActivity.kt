package io.github.vincentzyuapps.dartflutterdemo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dart_flutter_demo/home_widget")
            .setMethodCallHandler { call, result ->
                if (call.method != "syncHomeWidget") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val values = call.arguments as? Map<*, *>
                val disk = (values?.get("diskPercent") as? Number)?.toInt()
                val memory = (values?.get("memoryPercent") as? Number)?.toInt()
                val uptime = (values?.get("uptimeSeconds") as? Number)?.toLong()
                val preferences = getSharedPreferences("dart_flutter_demo_widget", MODE_PRIVATE)
                preferences.edit()
                    .putString("disk_percent", disk?.let { "${it.coerceIn(0, 100)}%" } ?: "--")
                    .putString("memory_percent", memory?.let { "${it.coerceIn(0, 100)}%" } ?: "--")
                    .putLong("boot_timestamp", uptime?.let { System.currentTimeMillis() - it * 1000L } ?: 0L)
                    .putString("uptime_text", uptime?.let(::formatUptime) ?: "--h --m --s")
                    .putString("version_text", versionText())
                    .apply()
                DemoAppWidgetProvider.refreshAll(this)
                result.success(null)
            }
    }

    private fun formatUptime(seconds: Long): String {
        val hours = seconds / 3600L
        val minutes = (seconds % 3600L) / 60L
        val remaining = seconds % 60L
        return "${hours}h ${minutes}m ${remaining}s"
    }

    private fun versionText(): String {
        @Suppress("DEPRECATION")
        val info = packageManager.getPackageInfo(packageName, 0)
        return "v${info.versionName?.substringBefore('+') ?: "?"}"
    }
}
