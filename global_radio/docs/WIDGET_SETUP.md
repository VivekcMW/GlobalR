# Home Screen Widgets Setup Guide

This guide explains how to set up the native home screen widgets for iOS and Android.

## Overview

Global Radio supports home screen widgets that show:
- **Now Playing**: Current playback info with play/pause control
- **Today's Astrology**: Quick access to daily astrology reading

## Flutter Integration

The `WidgetService` class in `lib/core/widget_service.dart` handles communication with native widgets via MethodChannel.

```dart
// Update widget with current playback
final widgetService = WidgetService();
await widgetService.updateNowPlaying(item, isPlaying: true);
```

---

## iOS Setup (WidgetKit)

### 1. Add Widget Extension in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. File → New → Target
3. Select "Widget Extension"
4. Name it `GlobalRadioWidget`
5. Uncheck "Include Configuration Intent" (for static widget)
6. Click Finish

### 2. Add App Group

1. Select the Runner target → Signing & Capabilities
2. Add "App Groups" capability
3. Create group: `group.app.globalradio.shared`
4. Repeat for the widget target

### 3. Widget Swift Code

Replace the generated widget code with:

```swift
// GlobalRadioWidget/GlobalRadioWidget.swift
import WidgetKit
import SwiftUI

struct WidgetData: Codable {
    let title: String
    let subtitle: String
    let interestIcon: String?
    let isPlaying: Bool
    let itemId: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: WidgetData(
            title: "Global Radio",
            subtitle: "Tap to start listening",
            interestIcon: "🎧",
            isPlaying: false,
            itemId: nil
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: loadData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), data: loadData())
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadData() -> WidgetData {
        let defaults = UserDefaults(suiteName: "group.app.globalradio.shared")
        guard let jsonString = defaults?.string(forKey: "widgetData"),
              let data = jsonString.data(using: .utf8),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return WidgetData(
                title: "Global Radio",
                subtitle: "Tap to start listening",
                interestIcon: "🎧",
                isPlaying: false,
                itemId: nil
            )
        }
        return widgetData
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct GlobalRadioWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.data.interestIcon ?? "🎧")
                    .font(.title)
                Spacer()
                if entry.data.isPlaying {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Text(entry.data.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(entry.data.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

@main
struct GlobalRadioWidget: Widget {
    let kind: String = "GlobalRadioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GlobalRadioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Global Radio")
        .description("Quick access to your personalized audio.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

### 4. Update AppDelegate for MethodChannel

Add to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import WidgetKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let widgetChannel = FlutterMethodChannel(
            name: "app.globalradio/widget",
            binaryMessenger: controller.binaryMessenger
        )
        
        widgetChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "updateWidget":
                if let args = call.arguments as? [String: Any] {
                    self?.updateWidget(args)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                }
            case "isSupported":
                result(true)
            case "requestAddWidget":
                // iOS doesn't support programmatic widget addition
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func updateWidget(_ data: [String: Any]) {
        let defaults = UserDefaults(suiteName: "group.app.globalradio.shared")
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            defaults?.set(jsonString, forKey: "widgetData")
        }
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
```

---

## Android Setup (Jetpack Glance)

### 1. Add Dependencies

Add to `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("androidx.glance:glance-appwidget:1.1.0")
}
```

### 2. Create Widget Files

Create `android/app/src/main/kotlin/app/globalradio/widget/GlobalRadioWidget.kt`:

```kotlin
package app.globalradio.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.*
import androidx.glance.layout.*
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import org.json.JSONObject
import app.globalradio.MainActivity

class GlobalRadioWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    @Composable
    override fun Content() {
        val context = LocalContext.current
        val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        val json = prefs.getString("data", null)
        
        val (title, subtitle, icon) = if (json != null) {
            val obj = JSONObject(json)
            Triple(
                obj.optString("title", "Global Radio"),
                obj.optString("subtitle", "Tap to start listening"),
                obj.optString("interestIcon", "🎧")
            )
        } else {
            Triple("Global Radio", "Tap to start listening", "🎧")
        }

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(16.dp)
                .background(GlanceTheme.colors.surface)
                .clickable(actionStartActivity<MainActivity>())
        ) {
            Text(
                text = icon,
                style = TextStyle(fontSize = 24.sp)
            )
            Spacer(GlanceModifier.height(8.dp))
            Text(
                text = title,
                style = TextStyle(fontSize = 16.sp),
                maxLines = 2
            )
            Spacer(GlanceModifier.height(4.dp))
            Text(
                text = subtitle,
                style = TextStyle(fontSize = 12.sp)
            )
        }
    }
}

class GlobalRadioWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = GlobalRadioWidget()
}
```

### 3. Register Widget in Manifest

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<receiver
    android:name=".widget.GlobalRadioWidgetReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/global_radio_widget_info" />
</receiver>
```

### 4. Create Widget Info XML

Create `android/app/src/main/res/xml/global_radio_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/glance_default_loading_layout"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:description="@string/widget_description"
    android:previewLayout="@layout/widget_preview" />
```

### 5. Update MainActivity for MethodChannel

Add to `android/app/src/main/kotlin/app/globalradio/MainActivity.kt`:

```kotlin
package app.globalradio

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import app.globalradio.widget.GlobalRadioWidgetReceiver

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.globalradio/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        val args = call.arguments as Map<*, *>
                        updateWidget(JSONObject(args).toString())
                        result.success(null)
                    }
                    "isSupported" -> result.success(true)
                    "requestAddWidget" -> {
                        requestPinWidget()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun updateWidget(jsonData: String) {
        getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            .edit()
            .putString("data", jsonData)
            .apply()

        val appWidgetManager = AppWidgetManager.getInstance(this)
        val component = ComponentName(this, GlobalRadioWidgetReceiver::class.java)
        val ids = appWidgetManager.getAppWidgetIds(component)
        appWidgetManager.notifyAppWidgetViewDataChanged(ids, android.R.id.text1)
    }

    private fun requestPinWidget() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val component = ComponentName(this, GlobalRadioWidgetReceiver::class.java)
            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                appWidgetManager.requestPinAppWidget(component, null, null)
            }
        }
    }
}
```

---

## Usage in Flutter

```dart
// In RadioController or where playback state changes
final widgetService = WidgetService();

// When playback starts
await widgetService.updateNowPlaying(currentItem, isPlaying: true);

// When playback stops
await widgetService.updateNowPlaying(currentItem, isPlaying: false);

// For today's astrology
await widgetService.updateTodayAstrology('Aries', 'hindi');
```

---

## Testing

### iOS
1. Run the app on a device/simulator
2. Long press on home screen → Add widget
3. Find "Global Radio" in the widget gallery
4. Add and verify it updates with playback

### Android
1. Run the app on a device/emulator (API 26+)
2. Long press on home screen → Widgets
3. Find "Global Radio" widget
4. Add and verify it updates with playback

---

## Notes

- iOS widgets refresh on a timeline (minimum 15 minutes)
- Android Glance widgets update when explicitly triggered
- Both platforms require the app to run at least once to populate data
- Deep links can be added to open specific content when widget is tapped
