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

  /// When the last ad finished (for the min-gap-minutes rule).
  final DateTime? lastAdAt;

  /// Start times of ads played this session (for the per-hour cap).
  final List<DateTime> adTimestamps;

  /// Session start time.
  final DateTime sessionStart;

  const AdSessionState({
    this.adsPlayedThisSession = 0,
    this.itemsSinceLastAd = 0,
    this.lastPlayedAdId,
    this.preRollShown = false,
    this.lastAdAt,
    this.adTimestamps = const [],
    DateTime? sessionStart,
  }) : sessionStart = sessionStart ?? const _DefaultDateTime();

  AdSessionState copyWith({
    int? adsPlayedThisSession,
    int? itemsSinceLastAd,
    String? lastPlayedAdId,
    bool? preRollShown,
    DateTime? lastAdAt,
    List<DateTime>? adTimestamps,
    DateTime? sessionStart,
    bool clearLastAdId = false,
  }) =>
      AdSessionState(
        adsPlayedThisSession: adsPlayedThisSession ?? this.adsPlayedThisSession,
        itemsSinceLastAd: itemsSinceLastAd ?? this.itemsSinceLastAd,
        lastPlayedAdId: clearLastAdId ? null : (lastPlayedAdId ?? this.lastPlayedAdId),
        preRollShown: preRollShown ?? this.preRollShown,
        lastAdAt: lastAdAt ?? this.lastAdAt,
        adTimestamps: adTimestamps ?? this.adTimestamps,
        sessionStart: sessionStart ?? this.sessionStart,
      );

  /// Ads played within the rolling hour before [now].
  int adsInLastHour(DateTime now) => adTimestamps
      .where((t) => now.difference(t) < const Duration(hours: 1))
      .length;

  /// Record that a content item was played.
  AdSessionState onContentPlayed() => copyWith(
        itemsSinceLastAd: itemsSinceLastAd + 1,
      );

  /// Record that an ad was played.
  AdSessionState onAdPlayed(String adId,
      {bool isPreRoll = false, DateTime? at}) {
    final when = at ?? DateTime.now();
    return copyWith(
      adsPlayedThisSession: adsPlayedThisSession + 1,
      itemsSinceLastAd: 0,
      lastPlayedAdId: adId,
      preRollShown: isPreRoll ? true : preRollShown,
      lastAdAt: when,
      adTimestamps: [...adTimestamps, when],
    );
  }

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
/// Implements frequency capping, premium skip and the hard no-ad gates
/// (kill switch, Kids Mode, day-0 grace period, bedtime runs).
class AdDecisionService {
  final AdConfig config;

  AdDecisionService({this.config = AdConfig.defaults});

  /// Gates common to every slot type. Returns a skip decision or null.
  AdDecision? _commonGates({
    required AdSessionState state,
    required bool isPremium,
    required bool isKidsMode,
    required bool inGracePeriod,
    required DateTime now,
  }) {
    // Remote kill switch: ads ship dark until Phase 2.
    if (!config.enabled) {
      return const AdDecision.skip(reason: 'Ads disabled (kill switch)');
    }

    // Kids Mode NEVER sees ads (store family policy + landing page promise).
    if (isKidsMode) {
      return const AdDecision.skip(reason: 'Kids Mode');
    }

    // Premium users never see ads.
    if (isPremium) {
      return const AdDecision.skip(reason: 'Premium user');
    }

    // Day-0 grace period: value before ads.
    if (inGracePeriod) {
      return const AdDecision.skip(reason: 'Install grace period');
    }

    // Session ad limit reached.
    if (state.adsPlayedThisSession >= config.maxAdsPerSession) {
      return const AdDecision.skip(reason: 'Session ad limit reached');
    }

    // Rolling per-hour cap.
    if (state.adsInLastHour(now) >= config.maxAdsPerHour) {
      return const AdDecision.skip(reason: 'Hourly ad limit reached');
    }

    return null;
  }

  /// Check if a pre-roll ad should be shown.
  AdDecision shouldShowPreRoll({
    required AdSessionState state,
    required bool isPremium,
    bool isKidsMode = false,
    bool inGracePeriod = false,
    DateTime? now,
  }) {
    final gate = _commonGates(
      state: state,
      isPremium: isPremium,
      isKidsMode: isKidsMode,
      inGracePeriod: inGracePeriod,
      now: now ?? DateTime.now(),
    );
    if (gate != null) return gate;

    // Pre-roll disabled in config
    if (!config.enablePreRoll) {
      return const AdDecision.skip(reason: 'Pre-roll disabled');
    }

    // Already shown pre-roll this session
    if (state.preRollShown) {
      return const AdDecision.skip(reason: 'Pre-roll already shown');
    }

    return const AdDecision.show(slotType: AdSlotType.preRoll);
  }

  /// Check if a mid-roll ad should be shown after the current item.
  AdDecision shouldShowMidRoll({
    required AdSessionState state,
    required bool isPremium,
    required int currentItemIndex,
    String? candidateAdId,
    bool isKidsMode = false,
    bool inGracePeriod = false,
    bool isBedtimeContent = false,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final gate = _commonGates(
      state: state,
      isPremium: isPremium,
      isKidsMode: isKidsMode,
      inGracePeriod: inGracePeriod,
      now: at,
    );
    if (gate != null) return gate;

    // Mid-roll disabled in config
    if (!config.enableMidRoll) {
      return const AdDecision.skip(reason: 'Mid-roll disabled');
    }

    // Never interrupt a bedtime/sleep run.
    if (isBedtimeContent && config.suppressDuringBedtime) {
      return const AdDecision.skip(reason: 'Bedtime run');
    }

    // Not enough content since last ad
    if (state.itemsSinceLastAd < config.minItemsBetweenAds) {
      return AdDecision.skip(
        reason: 'Only ${state.itemsSinceLastAd}/${config.minItemsBetweenAds} items since last ad',
      );
    }

    // Wall-clock gap rule: both item AND time gates must pass
    // (whichever is later wins).
    final lastAdAt = state.lastAdAt;
    if (lastAdAt != null && at.difference(lastAdAt) < config.minGapBetweenAds) {
      return AdDecision.skip(
        reason:
            'Only ${at.difference(lastAdAt).inMinutes}/${config.minGapBetweenAds.inMinutes} minutes since last ad',
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
    bool isKidsMode = false,
  }) {
    if (!config.enabled) return false;

    // Premium users and Kids Mode don't get ads in offline packs
    if (isPremium || isKidsMode) return false;

    // Only include ads for packs with enough content
    return packItemCount >= config.minItemsBetweenAds;
  }

  /// Calculate how many ads to include in an offline pack.
  int adsForOfflinePack({
    required int packItemCount,
    required bool isPremium,
    bool isKidsMode = false,
  }) {
    if (!config.enabled || isPremium || isKidsMode) return 0;

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
