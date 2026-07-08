# Planned features — not yet built

Specs for the highest-priority gaps identified against `launch-and-revenue-plan.md`'s
own roadmap (2026-07-08 review). Engagement/retention (streaks, milestones,
journeys, listener counts, sponsored stations — see `engagement-strategy.md`)
was checked against the actual code and found genuinely complete, not a gap.

Pick one and implement when ready — these are specs to build from, not yet
started.

---

## 1. Premium voice tier + family plan

**Why:** `launch-and-revenue-plan.md` Phase 4 lists "Premium voice tier
(ElevenLabs high-quality voice)" and "Family plan; annual-first pricing" as
planned revenue levers. Neither exists — `lib/data/services/payment_service.dart`
has exactly one product (`_premiumProductId = 'premium_subscription'`), and
`VoicePreset` (`lib/core/constants.dart`) has four presets, none gated behind
a *second*, higher-tier purchase (the existing `premium` flag on
`VoicePreset.devotional` just means "requires the base subscription", not "a
separate paid tier").

**Scope:**
- Add a second IAP product (e.g. `premium_voice_elevenlabs`) alongside
  `premium_subscription` in `payment_service.dart` — same `verifyPurchase`
  Cloud Function handles it (already generic on `productId`).
- New `VoicePreset` entries (or a `tier` field: free / premium / premium_voice)
  for ElevenLabs-rendered content — needs its own TTS render pass in the
  content pipeline (`tools/pipeline.py` would need an ElevenLabs backend
  alongside `edge`/`azure`, gated on an API key the same way Azure is).
- Family plan: a third product (`premium_family`) that, once purchased,
  should grant entitlement to multiple `userId`s. This needs a *design*
  decision the other two don't — how a family is formed (invite code? shared
  household email domain?) — before implementation, since `isPremium` is
  currently a per-user Firestore field with no concept of a group.

**Suggested order:** ship the voice tier first (small, reuses everything);
treat family plan as a separate, bigger design task (needs a `families`
Firestore collection + invite flow).

---

## 2. Paid content prioritization

**Why:** `launch-and-revenue-plan.md` Phase 2 lists "content prioritization
(paid featured placement, capped)" as a revenue stream, distinct from the
sponsored-station *card* that already exists (`lib/features/sponsored/sponsored_station.dart`
shows a dedicated card; it doesn't change what plays in the actual radio
queue).

**Scope:**
- `radio_engine`'s scoring/sequencing (see `docs/radio-sequencing-algorithm.md`)
  would need a `boostedItemIds` or `sponsoredWeight` input, sourced from a new
  Remote Config key (e.g. `prioritized_content_json`, same pattern as
  `sponsored_station_json` and `listener_counts_json` already in
  `remote_config_service.dart`) mapping item IDs to a ranking boost.
- Cap enforcement: the doc says "capped" — needs a rule like "at most 1 in N
  items boosted" so it can't crowd out organic content and erode trust (same
  guardrail philosophy as the ads system's frequency cap).
- Disclosure: per the sponsored-station card's precedent, boosted items
  should carry some visible "Featured" marker in the UI, not be silent.

**Suggested order:** build after #1, since it's a smaller, self-contained
change to `radio_engine` + one new Remote Config key + one UI marker.

---

## 3. AI4Bharat self-hosted TTS (infrastructure, not app code)

**Why:** `launch-and-revenue-plan.md` Phase 3 calls for AI4Bharat self-hosting
to cover Tier-2/3 long-tail languages beyond what free Edge TTS (10 languages)
and paid Azure (3 more: Odia, Punjabi, Assamese) reach. This is a *content
pipeline* addition, not a Flutter feature — a new backend option in
`tools/pipeline.py::resolve_voice`/`synth_azure`-equivalent, calling a
self-hosted AI4Bharat inference server instead of a cloud TTS API.

**Scope (rough — needs its own investigation pass before estimating):**
- Stand up an AI4Bharat TTS inference server (GPU-backed; not a simple API
  key like Azure).
- Add a `synth_ai4bharat()` function in `tools/pipeline.py`, mirroring
  `synth_azure()`'s shape.
- Extend `tools/content/voices.json` with an `ai4bharat` voice map for the
  Tier-2/3 languages in `AppLanguage.tier2` (`lib/core/constants.dart`).

**Suggested order:** last — meaningfully different kind of work (infra
ops, not app features), and only 3 Tier-1 languages are even blocked on
paid Azure currently; Tier-2/3 is a later-phase concern per the roadmap
itself.
