package com.example.dart_flutter_demo

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import java.util.concurrent.TimeUnit

class DemoAppWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val widgetPrefsName = "dart_flutter_demo_widget"
        private const val keyDiskPercent = "disk_percent"
        private const val keyMemoryPercent = "memory_percent"
        private const val keyBootTimestamp = "boot_timestamp"
        private const val keyUptimeText = "uptime_text"
        private const val keyVersionText = "version_text"
        private const val actionTick = "com.example.dart_flutter_demo.APPWIDGET_TICK"
        private const val tickRequestCode = 1042
        private const val refreshIntervalMs = 30_000L

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, DemoAppWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                ids.forEach { id ->
                    manager.updateAppWidget(id, buildRemoteViews(context))
                }
                scheduleNextTick(context)
            } else {
                cancelTick(context)
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(widgetPrefsName, Context.MODE_PRIVATE)
            val disk = prefs.getString(keyDiskPercent, "--") ?: "--"
            val memory = prefs.getString(keyMemoryPercent, "--") ?: "--"
            val uptime = formatDynamicUptime(
                prefs.getLong(keyBootTimestamp, 0L),
                prefs.getString(keyUptimeText, "--h --m --s") ?: "--h --m --s",
            )
            val version = prefs.getString(keyVersionText, "v?") ?: "v?"

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            return RemoteViews(context.packageName, R.layout.demo_widget).apply {
                setTextViewText(R.id.widget_version, version)
                setTextViewText(R.id.widget_disk_value, disk)
                setTextViewText(R.id.widget_memory_value, memory)
                setTextViewText(R.id.widget_uptime_value, uptime)
                if (launchIntent != null) {
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }
        }

        private fun formatDynamicUptime(bootTimestamp: Long, fallback: String): String {
            if (bootTimestamp <= 0L) return fallback
            val elapsedMs = (System.currentTimeMillis() - bootTimestamp).coerceAtLeast(0L)
            val totalSeconds = TimeUnit.MILLISECONDS.toSeconds(elapsedMs)
            val hours = totalSeconds / 3600
            val mins = (totalSeconds % 3600) / 60
            val secs = totalSeconds % 60
            return "${hours}h ${mins}m ${secs}s"
        }

        private fun scheduleNextTick(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
            val triggerAtMillis = SystemClock.elapsedRealtime() + refreshIntervalMs
            val pendingIntent = createTickPendingIntent(context)
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME,
                triggerAtMillis,
                pendingIntent,
            )
        }

        private fun cancelTick(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
            alarmManager.cancel(createTickPendingIntent(context))
        }

        private fun createTickPendingIntent(context: Context): PendingIntent {
            val tickIntent = Intent(context, DemoAppWidgetProvider::class.java).apply {
                action = actionTick
            }
            return PendingIntent.getBroadcast(
                context,
                tickRequestCode,
                tickIntent,
                pendingIntentFlags(),
            )
        }

        private fun pendingIntentFlags(): Int {
            val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
            return PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        DemoAppWidgetProvider.refreshAll(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, buildRemoteViews(context))
        }
        if (appWidgetIds.isNotEmpty()) {
            scheduleNextTick(context)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == actionTick) {
            refreshAll(context)
        }
    }

    override fun onDisabled(context: Context) {
        cancelTick(context)
        super.onDisabled(context)
    }
}
