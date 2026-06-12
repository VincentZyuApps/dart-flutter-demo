package com.example.dart_flutter_demo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class DemoAppWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val widgetPrefsName = "dart_flutter_demo_widget"
        private const val keyDiskPercent = "disk_percent"
        private const val keyMemoryPercent = "memory_percent"
        private const val keyUptimeText = "uptime_text"
        private const val keyVersionText = "version_text"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, DemoAppWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                ids.forEach { id ->
                    manager.updateAppWidget(id, buildRemoteViews(context))
                }
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(widgetPrefsName, Context.MODE_PRIVATE)
            val disk = prefs.getString(keyDiskPercent, "--") ?: "--"
            val memory = prefs.getString(keyMemoryPercent, "--") ?: "--"
            val uptime = prefs.getString(keyUptimeText, "--:--:--") ?: "--:--:--"
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
    }
}
