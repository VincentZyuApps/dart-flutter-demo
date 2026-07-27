package io.github.vincentzyuapps.system_info_vincentzyu

import android.app.ActivityManager
import android.content.Context
import android.net.ConnectivityManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.Locale

class SystemInfoVincentzyuPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "system_info_vincentzyu/methods")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInfo" -> result.success(getInfo())
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getInfo(): Map<String, Any?> {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo().also(activityManager::getMemoryInfo)
        val disk = StatFs(Environment.getDataDirectory().path)
        val totalDisk = disk.totalBytes
        val availableDisk = disk.availableBytes
        return mapOf(
            "operatingSystem" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT}) ${Build.SUPPORTED_ABIS.firstOrNull().orEmpty()}",
            "host" to listOf(Build.MANUFACTURER, Build.MODEL).filter { it.isNotBlank() }.joinToString(" "),
            "kernel" to System.getProperty("os.version"),
            "uptimeSeconds" to SystemClock.elapsedRealtime() / 1000L,
            "cpuModel" to cpuModel(),
            "logicalProcessors" to Runtime.getRuntime().availableProcessors(),
            "memoryUsedBytes" to (memory.totalMem - memory.availMem).coerceAtLeast(0L),
            "memoryTotalBytes" to memory.totalMem,
            "diskUsedBytes" to (totalDisk - availableDisk).coerceAtLeast(0L),
            "diskTotalBytes" to totalDisk,
            "localIp" to localIp(),
            "locale" to Locale.getDefault().toLanguageTag(),
        )
    }

    private fun cpuModel(): String {
        return try {
            File("/proc/cpuinfo").useLines { lines ->
                lines.firstOrNull {
                    it.startsWith("Hardware", true) || it.startsWith("model name", true)
                }?.substringAfter(':')?.trim()
            }.takeUnless { it.isNullOrBlank() } ?: Build.HARDWARE
        } catch (_: Exception) {
            Build.HARDWARE
        }
    }

    private fun localIp(): String? {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                val active = manager?.activeNetwork
                val address = active?.let(manager::getLinkProperties)?.linkAddresses
                    ?.firstOrNull { it.address is Inet4Address && usable(it.address.hostAddress) }
                    ?.address?.hostAddress?.substringBefore('%')
                if (!address.isNullOrBlank()) return address
            }

            val candidates = mutableListOf<Pair<Int, String>>()
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val network = interfaces.nextElement()
                if (!network.isUp || network.isLoopback) continue
                val addresses = network.inetAddresses
                while (addresses.hasMoreElements()) {
                    val value = addresses.nextElement()
                    val host = value.hostAddress?.substringBefore('%')
                    if (value is Inet4Address && usable(host)) {
                        candidates += interfaceScore(network.name) to host!!
                    }
                }
            }
            return candidates.minByOrNull { it.first }?.second
        } catch (_: Exception) {
            return null
        }
    }

    private fun usable(value: String?): Boolean =
        !value.isNullOrBlank() && !value.startsWith("127.") && !value.startsWith("169.254.")

    private fun interfaceScore(name: String): Int {
        val lower = name.lowercase(Locale.ROOT)
        return when {
            lower.contains("wifi") || lower.contains("wlan") -> 0
            lower.contains("eth") -> 1
            else -> 2
        }
    }
}
