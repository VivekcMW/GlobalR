package com.globalradio.global_radio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/** "Now playing" home-screen widget. Data arrives from Flutter through the
 *  `app.globalradio/widget` MethodChannel (see MainActivity) and is stored in
 *  SharedPreferences so the widget survives process death. */
class NowPlayingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    companion object {
        const val PREFS = "now_playing_widget"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, NowPlayingWidgetProvider::class.java)
            )
            for (id in ids) {
                manager.updateAppWidget(id, buildViews(context))
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val title = prefs.getString("title", "Global Radio") ?: "Global Radio"
            val subtitle =
                prefs.getString("subtitle", "Tap to start listening")
                    ?: "Tap to start listening"
            val icon = prefs.getString("interestIcon", "🎧") ?: "🎧"
            val isPlaying = prefs.getBoolean("isPlaying", false)

            val views = RemoteViews(context.packageName, R.layout.widget_now_playing)
            views.setTextViewText(R.id.widget_icon, icon)
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_subtitle, subtitle)
            views.setTextViewText(R.id.widget_status, if (isPlaying) "▶" else "")

            // Tapping the widget opens (or foregrounds) the app.
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            return views
        }
    }
}
