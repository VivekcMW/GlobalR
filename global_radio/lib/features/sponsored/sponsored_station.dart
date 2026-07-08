import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/remote_config_service.dart';
import '../../shared/providers/providers.dart';
import '../../shared/providers/radio_controller.dart';
import '../kids_mode/kids_mode_provider.dart';

/// A brand-sponsored curated station: a premium ad format shown to
/// free users instead of interruptive audio ads.
class SponsoredStation {
  final String id;
  final String name;
  final String tagline;
  final String sponsor;
  final List<String> interests;

  const SponsoredStation({
    required this.id,
    required this.name,
    required this.tagline,
    required this.sponsor,
    required this.interests,
  });

  /// Parse a direct-sold campaign from Remote Config JSON.
  /// Returns null for malformed or incomplete payloads.
  static SponsoredStation? fromJsonString(String json) {
    if (json.trim().isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final id = map['id'] as String?;
      final name = map['name'] as String?;
      final sponsor = map['sponsor'] as String?;
      final interests = (map['interests'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      if (id == null || name == null || sponsor == null || interests.isEmpty) {
        return null;
      }
      return SponsoredStation(
        id: id,
        name: name,
        tagline: map['tagline'] as String? ?? '',
        sponsor: sponsor,
        interests: interests,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The active sponsored station, if any. Sourced from the
/// `sponsored_station_json` Remote Config key (direct-sold campaigns).
/// Premium users and Kids Mode never see it; debug builds fall back to a
/// demo campaign so the card can be QA'd.
final sponsoredStationProvider = Provider<SponsoredStation?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile.isPremium) return null;
  if (ref.watch(kidsModeProvider)) return null;

  final rc = ref.watch(remoteConfigProvider);
  final campaign = SponsoredStation.fromJsonString(rc.sponsoredStationJson);
  if (campaign != null) return campaign;

  // No live campaign: show the demo card only in debug builds.
  if (!kDebugMode) return null;
  return const SponsoredStation(
    id: 'sp_morning_energy',
    name: 'Morning Energy',
    tagline: 'Motivation & devotion to start your day',
    sponsor: 'Global Radio Partners',
    interests: ['motivation', 'devotion'],
  );
});

/// Home card with a clear "Sponsored" disclosure.
class SponsoredStationCard extends ConsumerWidget {
  const SponsoredStationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(sponsoredStationProvider);
    if (station == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(Icons.campaign_outlined, color: scheme.secondary),
        title: Row(
          children: [
            Flexible(child: Text(station.name)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Sponsored',
                  style: TextStyle(
                      fontSize: 10, color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
        subtitle: Text('${station.tagline} · by ${station.sponsor}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () async {
          await ref
              .read(radioControllerProvider.notifier)
              .startRadio(onlyInterests: station.interests);
          if (context.mounted) context.push('/player');
        },
      ),
    );
  }
}
