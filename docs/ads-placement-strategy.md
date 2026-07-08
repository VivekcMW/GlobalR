# Ads Placement Strategy

How Global Radio serves ads without breaking the "radio feel" — aligned with
`launch-and-revenue-plan.md` (sponsorship-led, ads second, Rs 99/yr removes ads)
and the existing VAST infrastructure in `lib/features/ads/`.

---

## 1. Principles (non-negotiable)

1. **Radio-first.** Ads live *between* audio items, never interrupting one mid-play.
2. **Kids Mode = ZERO ads.** Promised on the landing page and store listing
   ("90+ kids stories · no ads"). Also required by Google Play Families policy.
3. **Premium = zero ads.** The single clearest upsell. Every ad ends with a
   1-line "Remove ads — Rs 99/year" house tag rotation (capped).
4. **Sponsorship > programmatic.** At <100K MAU, one direct sponsor pays more
   than all programmatic fill. Programmatic is the floor, not the ceiling.
5. **Everything remote-configurable.** Frequency, slots, kill switch — via
   Firebase Remote Config. Never ship a hardcoded ad decision.

---

## 2. Ad formats, ranked by priority

| # | Format | Sold how | Where | Value |
|---|--------|----------|-------|-------|
| 1 | **Sponsored station / channel** — "Devotion hour, presented by X" stinger + branded station tile | Direct | Station header + 1 audio stinger per session | Highest Rs/user; works at tiny scale |
| 2 | **Audio mid-roll** — 15–30s spot between items | Programmatic (VAST) + direct | Radio queue, every N items | Core scalable inventory |
| 3 | **Audio pre-roll** — ≤15s, skippable after 5s | Programmatic | Once per session, on first play | High completion; use sparingly |
| 4 | **Native content card** — "Sponsored" story/card styled like catalog items | Direct first, programmatic later | Today feed + Library lists | Non-intrusive display inventory |
| 5 | **House ads** — Premium promo, referral, new-language announcements | Own | Any unfilled slot | 100% fill fallback |

**Never:** full-screen interstitials, ads inside player controls, notification
ads, ads on the alarm/wake screen, autoplay video, rewarded ads (revisit later
only as "watch to unlock an offline save").

---

## 3. Placement map by surface

| Surface | Audio ads | Display/native | Notes |
|---|---|---|---|
| **Radio queue (player)** | Pre-roll ×1/session + mid-roll every N items | None on player screen | Keep player chrome clean; show "Ad · skip in 5s" state only |
| **Today feed** | — | 1 native sponsored card max, below the fold (position ≥4) | Clearly labeled "Sponsored" |
| **Library / category lists** | — | 1 native card per ~10 rows, max 2/screen | Direct-sold sponsor tiles first |
| **Kids Mode** | **NONE** | **NONE** | Hard-gated in `AdDecisionService`, not just UI |
| **Bedtime / sleep content** | No mid-rolls once a bedtime item starts a run | — | An ad at minute 40 of a sleep session destroys trust |
| **Car Mode** | Mid-roll audio only (same cadence) | None | No visual ads while driving |
| **Morning brief / alarm** | No pre-roll on alarm-triggered playback; single sponsor mention allowed ("Your morning brief, with X") | — | Waking someone to an ad = uninstall |
| **Offline playback** | Bundled offline house/sponsor spots only (`isOfflineAd`) | — | Already modeled in `AdCreative` |
| **Onboarding / first session** | **NONE** | **NONE** | Day-0 grace period; value before ads |

---

## 4. Frequency & pacing rules (Remote Config keys)

```
ads_enabled                 = false        # global kill switch (launch: OFF)
ads_midroll_every_n_items   = 4            # per revenue plan
ads_midroll_min_gap_minutes = 12           # whichever is LATER wins
ads_max_per_session         = 6
ads_max_per_hour            = 4
ads_preroll_enabled         = true         # 1 per session max
ads_grace_period_days       = 1            # no ads for brand-new installs
ads_house_ratio             = 0.25         # min share of house/premium promos
ads_bedtime_suppress        = true
```

- Session = existing `AdSessionState` (already tracks count, pre-roll shown, start time).
- **Gap rule beats item rule:** long items (10-min story) shouldn't get an ad
  after every single item just because N=4 was reached by short items earlier.
- Skip: default `skippableAfter5s` (already the model default). Non-skippable
  only for ≤15s direct-sold spots.

---

## 5. Serving stack by phase

| Phase (revenue plan) | Stack |
|---|---|
| **Phase 1 — Launch (now)** | `ads_enabled=false`. House ads only if any slot renders. Ship the decision pipeline dark so Phase 2 is a config flip. |
| **Phase 2 — Months 3–4** | Turn on: Google Ad Manager audio VAST tags (replace the test tags in `ad_service.dart`), 1–2 direct sponsors served as house creatives with priority over programmatic. Native cards: direct-sold only. |
| **Phase 3 — Months 5–8** | Add AdMob native for list cards; A/B N=4 vs N=5 vs gap-only on retention. |
| **Phase 4 — Months 9–12** | Mediation (AdMob mediation or GAM) for fill/eCPM; audio ad networks with India inventory; self-serve sponsor kit. |

**Waterfall per slot:** direct-sold → programmatic VAST → house ad. Never an empty/error state (fallback creative already exists).

---

## 6. Compliance checklist

- [ ] **Google Play Families / Apple Kids**: Kids Mode gated server-side of the
      decision (no ad SDK calls at all while `kidsMode == true`).
- [ ] **Consent**: Google UMP SDK for GDPR/consent; ATT prompt on iOS *only if*
      serving personalized ads — prefer **non-personalized/contextual ads at
      launch** (skip ATT, simpler privacy labels; already declared "no tracking").
- [ ] **India DPDP Act**: contextual ads keep us out of consent-manager scope.
- [ ] **app-ads.txt** at `https://globalradio.app/app-ads.txt` before any
      programmatic goes live (add to `site/`).
- [ ] "Sponsored" / "Ad" labels on every paid unit (ASCI guidelines, store policy).
- [ ] Update store privacy labels + PRIVACY.md when the ad SDK lands (currently
      declared ad-free data practices — must revise in Phase 2, not before).

---

## 7. Metrics & guardrails

| Metric | Target / guardrail |
|---|---|
| Ads per DAU | 3–5 (free users) |
| Mid-roll completion rate | > 70% (audio norm) |
| Skip rate | < 40%; higher → creative or cadence problem |
| Fill rate (programmatic) | > 60% with house fallback covering the rest |
| eCPM (India audio) | Rs 20–80 expectation; don't chase eCPM at retention's cost |
| **D30 retention delta (ads on vs off)** | **< 2pp drop, else reduce cadence** — run as holdout A/B |
| Premium conversion from "remove ads" taps | Track as primary upsell funnel |

The retention holdout is the most important number: the revenue plan's GO/NO-GO
gate is D30 ≥ 10%, and ads must never be the reason we miss it.

---

## 8. Implementation gap list (existing code → done)

Already built in `lib/features/ads/`:
- ✅ `AdCreative`/VAST models, pre-roll + mid-roll slot types, skip policies
- ✅ `AdSessionState` frequency capping, `AdDecisionService`
- ✅ `AdTrackingService` (impression/complete/skip/error beacons)
- ✅ Premium gating (`adsDisabledProvider` reads `profile.isPremium`)
- ✅ Offline fallback creative
- ✅ `sponsored_station.dart` scaffold

To do (Phase 2 flip):
- [x] Wire frequency knobs to Firebase Remote Config (`adConfigProvider` reads all `ads_*` keys; compiled defaults ship dark)
- [x] Hard kids-mode gate inside `AdDecisionService` (belt-and-braces, plus `adsDisabledProvider`)
- [x] Bedtime-run suppression rule (`isBedtimeContent` gate, `ads_bedtime_suppress` knob)
- [x] Min-gap-minutes rule alongside every-N-items (both must pass; whichever is later wins)
- [x] Production VAST tag via Remote Config (`ads_vast_tag_url`; test tag remains the dev fallback)
- [x] House ad rotation (`house_ads.dart` + bundled TTS promo spots in `assets/audio/ads/`; reserved slots via `ads_house_ratio`, waterfall fallback on VAST failure)
- [x] Native sponsored card driven by `sponsored_station_json` Remote Config (kids/premium gated; demo campaign debug-only)
- [x] `site/app-ads.txt` (seller records commented until the real AdMob publisher ID exists)
- [x] Analytics events: `ad_requested/ad_failed` + existing impression/complete/skip, `premium_upsell_from_ad` (Remove-ads CTA on the ad overlay)
- [ ] Privacy label/PRIVACY.md revision — do this when programmatic actually flips ON, not before
- [ ] Replace commented app-ads.txt records with the real publisher ID (needs AdMob account)
- [ ] Retention holdout A/B (needs Firebase A/B Testing setup at Phase 2 flip)
