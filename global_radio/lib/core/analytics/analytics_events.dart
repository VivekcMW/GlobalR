/// Analytics events for tracking user behavior and app metrics.
/// 
/// These typed events ensure consistent tracking across the app and
/// enable proper A/B testing and funnel analysis.
library;

/// Base class for all analytics events.
sealed class AnalyticsEvent {
  String get name;
  Map<String, Object> get parameters;
}

// ============================================================================
// App Lifecycle Events
// ============================================================================

/// User opens the app.
class AppOpenEvent extends AnalyticsEvent {
  final String? source;
  final String? referralCode;

  AppOpenEvent({this.source, this.referralCode});

  @override
  String get name => 'app_open';

  @override
  Map<String, Object> get parameters => {
        if (source != null) 'source': source!,
        if (referralCode != null) 'referral_code': referralCode!,
      };
}

/// User completes onboarding.
class OnboardCompleteEvent extends AnalyticsEvent {
  final List<String> languages;
  final List<String> interests;
  final String? voicePreference;

  OnboardCompleteEvent({
    required this.languages,
    required this.interests,
    this.voicePreference,
  });

  @override
  String get name => 'onboard_complete';

  @override
  Map<String, Object> get parameters => {
        'language_count': languages.length,
        'languages': languages.join(','),
        'interest_count': interests.length,
        'interests': interests.join(','),
        if (voicePreference != null) 'voice': voicePreference!,
      };
}

/// User skips onboarding.
class OnboardSkipEvent extends AnalyticsEvent {
  final String step;

  OnboardSkipEvent({required this.step});

  @override
  String get name => 'onboard_skip';

  @override
  Map<String, Object> get parameters => {'step': step};
}

// ============================================================================
// Playback Events
// ============================================================================

/// User starts playing content.
class PlayStartEvent extends AnalyticsEvent {
  final String itemId;
  final String contentType;
  final String interest;
  final String language;
  final bool isDaily;
  final String? source; // 'home', 'library', 'player', 'notification'

  PlayStartEvent({
    required this.itemId,
    required this.contentType,
    required this.interest,
    required this.language,
    required this.isDaily,
    this.source,
  });

  @override
  String get name => 'play_start';

  @override
  Map<String, Object> get parameters => {
        'item_id': itemId,
        'content_type': contentType,
        'interest': interest,
        'language': language,
        'is_daily': isDaily,
        if (source != null) 'source': source!,
      };
}

/// User skips to the next item.
class PlaySkipEvent extends AnalyticsEvent {
  final String itemId;
  final String contentType;
  final String interest;
  final int secondsPlayed;
  final int totalSeconds;

  PlaySkipEvent({
    required this.itemId,
    required this.contentType,
    required this.interest,
    required this.secondsPlayed,
    required this.totalSeconds,
  });

  @override
  String get name => 'play_skip';

  @override
  Map<String, Object> get parameters => {
        'item_id': itemId,
        'content_type': contentType,
        'interest': interest,
        'seconds_played': secondsPlayed,
        'total_seconds': totalSeconds,
        'percent_played': totalSeconds > 0
            ? ((secondsPlayed / totalSeconds) * 100).round()
            : 0,
      };
}

/// User completes playing an item.
class PlayCompleteEvent extends AnalyticsEvent {
  final String itemId;
  final String contentType;
  final String interest;
  final String language;
  final int durationSeconds;

  PlayCompleteEvent({
    required this.itemId,
    required this.contentType,
    required this.interest,
    required this.language,
    required this.durationSeconds,
  });

  @override
  String get name => 'play_complete';

  @override
  Map<String, Object> get parameters => {
        'item_id': itemId,
        'content_type': contentType,
        'interest': interest,
        'language': language,
        'duration_seconds': durationSeconds,
      };
}

// ============================================================================
// Session Events
// ============================================================================

/// Radio session starts.
class SessionStartEvent extends AnalyticsEvent {
  final List<String> interests;
  final int queueLength;

  SessionStartEvent({
    required this.interests,
    required this.queueLength,
  });

  @override
  String get name => 'session_start';

  @override
  Map<String, Object> get parameters => {
        'interests': interests.join(','),
        'queue_length': queueLength,
      };
}

/// Radio session ends.
class SessionEndEvent extends AnalyticsEvent {
  final int durationSeconds;
  final int itemsPlayed;
  final int itemsSkipped;

  SessionEndEvent({
    required this.durationSeconds,
    required this.itemsPlayed,
    required this.itemsSkipped,
  });

  @override
  String get name => 'session_end';

  @override
  Map<String, Object> get parameters => {
        'duration_seconds': durationSeconds,
        'items_played': itemsPlayed,
        'items_skipped': itemsSkipped,
      };
}

// ============================================================================
// Feature Usage Events
// ============================================================================

/// User changes playback speed.
class SpeedChangeEvent extends AnalyticsEvent {
  final double speed;

  SpeedChangeEvent({required this.speed});

  @override
  String get name => 'speed_change';

  @override
  Map<String, Object> get parameters => {'speed': speed};
}

/// User sets sleep timer.
class SleepTimerSetEvent extends AnalyticsEvent {
  final int minutes; // -1 for end of episode

  SleepTimerSetEvent({required this.minutes});

  @override
  String get name => 'sleep_timer_set';

  @override
  Map<String, Object> get parameters => {'minutes': minutes};
}

/// User favorites an item.
class FavoriteEvent extends AnalyticsEvent {
  final String itemId;
  final String interest;
  final bool isFavorite;

  FavoriteEvent({
    required this.itemId,
    required this.interest,
    required this.isFavorite,
  });

  @override
  String get name => 'favorite';

  @override
  Map<String, Object> get parameters => {
        'item_id': itemId,
        'interest': interest,
        'is_favorite': isFavorite,
      };
}

/// User downloads content for offline use.
class DownloadEvent extends AnalyticsEvent {
  final String itemId;
  final String action; // 'start', 'complete', 'cancel', 'delete'
  final int? sizeBytes;

  DownloadEvent({
    required this.itemId,
    required this.action,
    this.sizeBytes,
  });

  @override
  String get name => 'download';

  @override
  Map<String, Object> get parameters => {
        'item_id': itemId,
        'action': action,
        if (sizeBytes != null) 'size_bytes': sizeBytes!,
      };
}

/// User shares content.
class ShareEvent extends AnalyticsEvent {
  final String itemId;
  final String contentType;
  final String method; // 'link', 'social'

  ShareEvent({
    required this.itemId,
    required this.contentType,
    required this.method,
  });

  @override
  String get name => 'share';

  @override
  Map<String, Object> get parameters => {
        'item_id': itemId,
        'content_type': contentType,
        'method': method,
      };
}

// ============================================================================
// Push Notification Events
// ============================================================================

/// Push notification received.
class PushReceivedEvent extends AnalyticsEvent {
  final String topic;
  final String? itemId;

  PushReceivedEvent({required this.topic, this.itemId});

  @override
  String get name => 'push_received';

  @override
  Map<String, Object> get parameters => {
        'topic': topic,
        if (itemId != null) 'item_id': itemId!,
      };
}

/// User taps push notification.
class PushOpenedEvent extends AnalyticsEvent {
  final String topic;
  final String? itemId;

  PushOpenedEvent({required this.topic, this.itemId});

  @override
  String get name => 'push_opened';

  @override
  Map<String, Object> get parameters => {
        'topic': topic,
        if (itemId != null) 'item_id': itemId!,
      };
}

// ============================================================================
// A/B Testing Events
// ============================================================================

/// User enrolled in an experiment.
class ExperimentEnrolledEvent extends AnalyticsEvent {
  final String experimentId;
  final String variant;

  ExperimentEnrolledEvent({
    required this.experimentId,
    required this.variant,
  });

  @override
  String get name => 'experiment_enrolled';

  @override
  Map<String, Object> get parameters => {
        'experiment_id': experimentId,
        'variant': variant,
      };
}

/// User converted in an experiment.
class ExperimentConvertedEvent extends AnalyticsEvent {
  final String experimentId;
  final String variant;
  final String goal;

  ExperimentConvertedEvent({
    required this.experimentId,
    required this.variant,
    required this.goal,
  });

  @override
  String get name => 'experiment_converted';

  @override
  Map<String, Object> get parameters => {
        'experiment_id': experimentId,
        'variant': variant,
        'goal': goal,
      };
}

// ============================================================================
// Screen View Events
// ============================================================================

/// User views a screen.
class ScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  final String? screenClass;

  ScreenViewEvent({required this.screenName, this.screenClass});

  @override
  String get name => 'screen_view';

  @override
  Map<String, Object> get parameters => {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass!,
      };
}

// ============================================================================
// Premium & Purchase Events
// ============================================================================

/// User views premium upsell.
class PremiumViewEvent extends AnalyticsEvent {
  final String source; // 'settings', 'ad_prompt', 'voice_limit', etc.

  PremiumViewEvent({required this.source});

  @override
  String get name => 'premium_view';

  @override
  Map<String, Object> get parameters => {'source': source};
}

/// User initiates premium purchase.
class PurchaseInitEvent extends AnalyticsEvent {
  final String productId;
  final String source;

  PurchaseInitEvent({required this.productId, required this.source});

  @override
  String get name => 'purchase_init';

  @override
  Map<String, Object> get parameters => {
        'product_id': productId,
        'source': source,
      };
}

/// Purchase completed successfully.
class PurchaseCompleteEvent extends AnalyticsEvent {
  final String productId;
  final double price;
  final String currency;

  PurchaseCompleteEvent({
    required this.productId,
    required this.price,
    required this.currency,
  });

  @override
  String get name => 'purchase_complete';

  @override
  Map<String, Object> get parameters => {
        'product_id': productId,
        'price': price,
        'currency': currency,
      };
}

/// Purchase failed or cancelled.
class PurchaseFailEvent extends AnalyticsEvent {
  final String productId;
  final String reason; // 'cancelled', 'error', 'declined'

  PurchaseFailEvent({required this.productId, required this.reason});

  @override
  String get name => 'purchase_fail';

  @override
  Map<String, Object> get parameters => {
        'product_id': productId,
        'reason': reason,
      };
}

// ============================================================================
// Ad Events
// ============================================================================

/// Ad impression.
class AdImpressionEvent extends AnalyticsEvent {
  final String adType; // 'pre_roll', 'mid_roll'
  final String? adSource;

  AdImpressionEvent({required this.adType, this.adSource});

  @override
  String get name => 'ad_impression';

  @override
  Map<String, Object> get parameters => {
        'ad_type': adType,
        if (adSource != null) 'ad_source': adSource!,
      };
}

/// Ad skipped.
class AdSkipEvent extends AnalyticsEvent {
  final String adType;
  final int secondsWatched;

  AdSkipEvent({required this.adType, required this.secondsWatched});

  @override
  String get name => 'ad_skip';

  @override
  Map<String, Object> get parameters => {
        'ad_type': adType,
        'seconds_watched': secondsWatched,
      };
}

/// Ad completed.
class AdCompleteEvent extends AnalyticsEvent {
  final String adType;
  final int durationSeconds;

  AdCompleteEvent({required this.adType, required this.durationSeconds});

  @override
  String get name => 'ad_complete';

  @override
  Map<String, Object> get parameters => {
        'ad_type': adType,
        'duration_seconds': durationSeconds,
      };
}

// ============================================================================
// Referral Events
// ============================================================================

/// User shares referral link.
class ReferralShareEvent extends AnalyticsEvent {
  final String method; // 'copy', 'whatsapp', 'sms', etc.

  ReferralShareEvent({required this.method});

  @override
  String get name => 'referral_share';

  @override
  Map<String, Object> get parameters => {'method': method};
}

/// User redeems referral code.
class ReferralRedeemEvent extends AnalyticsEvent {
  final String code;
  final bool success;

  ReferralRedeemEvent({required this.code, required this.success});

  @override
  String get name => 'referral_redeem';

  @override
  Map<String, Object> get parameters => {
        'code': code,
        'success': success,
      };
}

// ============================================================================
// Voice Search Events
// ============================================================================

/// Voice search initiated.
class VoiceSearchStartEvent extends AnalyticsEvent {
  @override
  String get name => 'voice_search_start';

  @override
  Map<String, Object> get parameters => {};
}

/// Voice search completed.
class VoiceSearchResultEvent extends AnalyticsEvent {
  final String? query;
  final int resultCount;
  final bool success;

  VoiceSearchResultEvent({
    this.query,
    required this.resultCount,
    required this.success,
  });

  @override
  String get name => 'voice_search_result';

  @override
  Map<String, Object> get parameters => {
        if (query != null) 'query': query!,
        'result_count': resultCount,
        'success': success,
      };
}

// ============================================================================
// Parental Controls Events
// ============================================================================

/// Parental controls enabled/disabled.
class ParentalControlsEvent extends AnalyticsEvent {
  final bool enabled;

  ParentalControlsEvent({required this.enabled});

  @override
  String get name => 'parental_controls';

  @override
  Map<String, Object> get parameters => {'enabled': enabled};
}

// ============================================================================
// Feedback Events
// ============================================================================

/// User submits feedback.
class FeedbackSubmitEvent extends AnalyticsEvent {
  final String type; // 'bug', 'feature', 'other'
  final int? rating;

  FeedbackSubmitEvent({required this.type, this.rating});

  @override
  String get name => 'feedback_submit';

  @override
  Map<String, Object> get parameters => {
        'type': type,
        if (rating != null) 'rating': rating!,
      };
}

// ============================================================================
// Error Events
// ============================================================================

/// Error occurred.
class ErrorEvent extends AnalyticsEvent {
  final String errorType;
  final String? message;
  final String? screen;

  ErrorEvent({
    required this.errorType,
    this.message,
    this.screen,
  });

  @override
  String get name => 'error';

  @override
  Map<String, Object> get parameters => {
        'error_type': errorType,
        if (message != null) 'message': message!,
        if (screen != null) 'screen': screen!,
      };
}
