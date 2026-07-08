package com.globalradio.global_radio

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends AudioServiceActivity so background audio (audio_service) works on Android.
class MainActivity : AudioServiceActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app.globalradio/widget"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val prefs = getSharedPreferences(
                        NowPlayingWidgetProvider.PREFS, Context.MODE_PRIVATE
                    )
                    prefs.edit()
                        .putString("title", call.argument<String>("title") ?: "Global Radio")
                        .putString("subtitle", call.argument<String>("subtitle") ?: "")
                        .putString("interestIcon", call.argument<String>("interestIcon") ?: "🎧")
                        .putBoolean("isPlaying", call.argument<Boolean>("isPlaying") ?: false)
                        .apply()
                    NowPlayingWidgetProvider.updateAll(this)
                    result.success(null)
                }
                "isSupported" -> result.success(true)
                "requestAddWidget" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val manager = getSystemService(AppWidgetManager::class.java)
                        val component =
                            ComponentName(this, NowPlayingWidgetProvider::class.java)
                        if (manager?.isRequestPinAppWidgetSupported == true) {
                            manager.requestPinAppWidget(component, null, null)
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
