import 'ad_models.dart';

/// Session-scoped state for ad frequency capping.
/// Resets when the app is backgrounded or restarted.
class AdSessionState {
  /// Number of ads played in this session.
  final int adsPlayedThisSession;

  /// Content items played since the last ad.
  final int itemsSinceLastAd;

  /// ID of the last played ad (for duplicate blocking).
  final String? lastPlayedAdId;

  /// Whether pre-roll has been shown this session.
  final bool preRollShown;

  /// Session start time.
  final DateTime sessionStart;

  const AdSessionState({
    this.adsPlayedThisSession = 0,
    this.itemsSinceLastAd = 0,
    this.lastPlayedAdId,
    this.preRollShown = false,
    DateTime? sessionStart,
  }) : sessionStart = sessionStart ?? const _DefaultDateTime();

  AdSessionState copyWith({
    int? adsPlayedThisSession,
    int? itemsSinceLastAd,
    String? lastPlayedAdId,
    bool? preRollShown,
    DateTime? sessionStart,
    bool clearLastAdId = false,
  }) =>
      AdSessionState(
        adsPlayedThisSession: adsPlayedThisSession ?? this.adsPlayedThisSession,
        itemsSinceLastAd: itemsSinceLastAd ?? this.itemsSinceLastAd,
        lastPlayedAdId: clearLastAdId ? null : (lastPlayedAdId ?? this.lastPlayedAdId),
        preRollShown: preRollShown ?? this.preRollShown,
        sessionStart: sessionStart ?? this.sessionStart,
      );

  /// Record that a content item was played.
  AdSessionState onContentPlayed() => copyWith(
        itemsSinceLastAd: itemsSinceLastAd + 1,
      );

  /// Record that an ad was played.
  AdSessionState onAdPlayed(String adId, {bool isPreRoll = false}) => copyWith(
        adsPlayedThisSession: adsPlayedThisSession + 1,
        itemsSinceLastAd: 0,
        lastPlayedAdId: adId,
        preRollShown: isPreRoll ? true : preRollShown,
      );

  /// Reset for a new session.
  factory AdSessionState.newSession() => AdSessionState(
        sessionStart: DateTime.now(),
      );
}

/// Workaround for const DateTime.now() not being available.
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  bool get isUtc => _now.isUtc;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();

  @override
  String toString() => _now.toString();
}

/// Decision engine for ad insertion.
/// Implements frequency capping and premium user skip.
class AdDecisionService {
  final AdConfig config;

  AdDecisionService({this.config = AdConfig.defaults});

  /// Check if a pre-roll ad should be shown.
  AdDecision shouldShowPreRoll({
    required AdSessionState state,
    required bool isPremium,
  }) {
    // Premium users never see ads
    if (isPremium) {
      return const AdDecision.skip(reason: 'Premium user');
    }

    // Pre-roll disabled in config
    if (!config.enablePreRoll) {
      return const AdDecision.skip(reason: 'Pre-roll disabled');
    }

    // Already shown pre-roll this session
    if (state.preRollShown) {
      return const AdDecision.skip(reason: 'Pre-roll already shown');
    }

    // Session ad limit reached
    if (state.adsPlayedThisSession >= config.maxAdsPerSession) {
      return const AdDecision.skip(reason: 'Session ad limit reached');
    }

    return const AdDecision.show(slotType: AdSlotType.preRoll);
  }

  /// Check if a mid-roll ad should be shown after the current item.
  AdDecision shouldShowMidRoll({
    required AdSessionState state,
    required bool isPremium,
    required int currentItemIndex,
    String? candidateAdId,
  }) {
    // Premium users never see ads
    if (isPremium) {
      return const AdDecision.skip(reason: 'Premium user');
    }

    // Mid-roll disabled in config
    if (!config.enableMidRoll) {
      return const AdDecision.skip(reason: 'Mid-roll disabled');
    }

    // Session ad limit reached
    if (state.adsPlayedThisSession >= config.maxAdsPerSession) {
      return const AdDecision.skip(reason: 'Session ad limit reached');
    }

    // Not enough content since last ad
    if (state.itemsSinceLastAd < config.minItemsBetweenAds) {
      return AdDecision.skip(
        reason: 'Only ${state.itemsSinceLastAd}/${config.minItemsBetweenAds} items since last ad',
      );
    }

    // Don't show the same ad twice in a row
    if (candidateAdId != null && candidateAdId == state.lastPlayedAdId) {
      return const AdDecision.skip(reason: 'Same ad as last time');
    }

    return AdDecision.show(
      slotType: AdSlotType.midRoll,
      insertAfterIndex: currentItemIndex,
    );
  }

  /// Check if ads should be included in an offline download pack.
  bool shouldIncludeAdsInOfflinePack({
    required bool isPremium,
    required int packItemCount,
  }) {
    // Premium users don't get ads in offline packs
    if (isPremium) return false;

    // Only include ads for packs with enough content
    return packItemCount >= config.minItemsBetweenAds;
  }

  /// Calculate how many ads to include in an offline pack.
  int adsForOfflinePack({
    required int packItemCount,
    required bool isPremium,
  }) {
    if (isPremium) return 0;

    // One ad per minItemsBetweenAds items, capped at maxAdsPerSession
    final adCount = (packItemCount / config.minItemsBetweenAds).floor();
    return adCount.clamp(0, config.maxAdsPerSession);
  }
}

/// Result of an ad decision check.
class AdDecision {
  final bool show;
  final String? reason;
  final AdSlotType? slotType;
  final int? insertAfterIndex;

  const AdDecision._({
    required this.show,
    this.reason,
    this.slotType,
    this.insertAfterIndex,
  });

  const AdDecision.show({
    required AdSlotType slotType,
    int? insertAfterIndex,
  }) : this._(
          show: true,
          slotType: slotType,
          insertAfterIndex: insertAfterIndex ?? -1,
        );

  const AdDecision.skip({required String reason})
      : this._(show: false, reason: reason);

  @override
  String toString() => show
      ? 'AdDecision.show($slotType at $insertAfterIndex)'
      : 'AdDecision.skip($reason)';
}
