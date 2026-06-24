import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/catalog_item.dart';

/// Data to display in the home screen widget.
class WidgetData {
  final String title;
  final String subtitle;
  final String? interestIcon;
  final bool isPlaying;
  final String? itemId;

  const WidgetData({
    required this.title,
    required this.subtitle,
    this.interestIcon,
    this.isPlaying = false,
    this.itemId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'interestIcon': interestIcon,
        'isPlaying': isPlaying,
        'itemId': itemId,
      };

  factory WidgetData.fromItem(CatalogItem item, {bool isPlaying = false}) {
    return WidgetData(
      title: item.title,
      subtitle: item.primaryInterest,
      interestIcon: _interestIcon(item.primaryInterest),
      isPlaying: isPlaying,
      itemId: item.id,
    );
  }

  factory WidgetData.todayAstrology(String sign, String language) {
    return WidgetData(
      title: "Today's $sign",
      subtitle: 'Daily Astrology',
      interestIcon: '✨',
    );
  }

  factory WidgetData.empty() {
    return const WidgetData(
      title: 'Global Radio',
      subtitle: 'Tap to start listening',
      interestIcon: '🎧',
    );
  }

  static String _interestIcon(String interest) {
    switch (interest) {
      case 'kids':
        return '🧒';
      case 'moral':
        return '📖';
      case 'devotion':
        return '🪔';
      case 'astrology':
        return '✨';
      default:
        return '🎧';
    }
  }
}

/// Service for communicating with native home screen widgets.
class WidgetService {
  static const _channel = MethodChannel('app.globalradio/widget');
  
  /// Update the widget with new data.
  Future<void> updateWidget(WidgetData data) async {
    try {
      await _channel.invokeMethod('updateWidget', data.toJson());
    } on PlatformException catch (e) {
      // Widget update failed - likely widget not installed or platform issue
      if (kDebugMode) {
        print('Widget update failed: ${e.message}');
      }
    }
  }

  /// Update widget with currently playing item.
  Future<void> updateNowPlaying(CatalogItem? item, {bool isPlaying = false}) async {
    final data = item != null
        ? WidgetData.fromItem(item, isPlaying: isPlaying)
        : WidgetData.empty();
    await updateWidget(data);
  }

  /// Update widget with today's astrology.
  Future<void> updateTodayAstrology(String sign, String language) async {
    await updateWidget(WidgetData.todayAstrology(sign, language));
  }

  /// Check if widget is supported on this platform.
  Future<bool> isWidgetSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Request user to add the widget (shows system UI).
  Future<void> requestAddWidget() async {
    try {
      await _channel.invokeMethod('requestAddWidget');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Request add widget failed: ${e.message}');
      }
    }
  }
}
