package io.github.vincentzyuapps.dartflutterdemo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews

class DemoAppWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val preferencesName = "dart_flutter_demo_widget"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, DemoAppWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach {
                manager.updateAppWidget(it, buildViews(context))
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            val pending = launch?.let {
                PendingIntent.getActivity(
                    context, 0, it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            }
            return RemoteViews(context.packageName, R.layout.demo_widget).apply {
                setTextViewText(R.id.widget_version, preferences.getString("version_text", "v?"))
                setTextViewText(R.id.widget_disk_value, preferences.getString("disk_percent", "--"))
                setTextViewText(R.id.widget_memory_value, preferences.getString("memory_percent", "--"))
                val boot = preferences.getLong("boot_timestamp", 0L)
                if (boot > 0L) {
                    val base = (SystemClock.elapsedRealtime() -
                        (System.currentTimeMillis() - boot)).coerceAtLeast(0L)
                    setChronometer(R.id.widget_uptime_value, base, null, true)
                } else {
                    setTextViewText(R.id.widget_uptime_value,
                        preferences.getString("uptime_text", "--h --m --s"))
                }
                if (pending != null) setOnClickPendingIntent(R.id.widget_root, pending)
            }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { manager.updateAppWidget(it, buildViews(context)) }
    }
}
