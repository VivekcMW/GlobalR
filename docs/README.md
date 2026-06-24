# Global Radio — India Interest Radio (Project Docs)

A personalized audio "interest radio" for India that turns legally-safe content
(kids' stories, moral stories, devotion, astrology, and more) into a continuous,
personalized listening experience across iOS + Android. Lightweight, data-frugal,
no audio-streaming backend.

## Documents

| Doc | What's inside |
|---|---|
| [technical-build-spec.md](./technical-build-spec.md) | Flutter (hybrid) architecture, on-device radio engine, catalog schema, voice selection, daily astrology pipeline, lightweight tactics, screens, build effort |
| [language-coverage-matrix.md](./language-coverage-matrix.md) | All 22 official Indian languages + English, TTS engine tiering (Azure / AI4Bharat), per-language readiness, QA gate |
| [legal-safe-launch-checklist.md](./legal-safe-launch-checklist.md) | Per-interest legally-safe content sources, license traps to avoid, compliance gates |
| [design-and-payments-spec.md](./design-and-payments-spec.md) | Material 3 design system, "Calm Audio, Indian Warmth" style, design tokens, user + payment workflows, Razorpay/IAP architecture, Flutter theme starter |
| [radio-sequencing-algorithm.md](./radio-sequencing-algorithm.md) | Full on-device pseudocode: filter, scoring, sequencing ("radio feel"), live re-ranking, cold start, voice resolution, tunable weights |
| [launch-and-revenue-plan.md](./launch-and-revenue-plan.md) | 12-month India plan: phases, install/MAU/revenue targets, monetization priority, risks, weekly metrics |

## Key decisions at a glance

- **Framework:** Flutter (compiled hybrid; NOT WebView) for reliable background audio on iOS + Android.
- **No streaming backend:** static `catalog.json` + pre-rendered MP3s on CDN (Cloudflare R2, zero egress); the "radio" is sequenced on-device.
- **Content is legally safe:** CC BY (Pratham StoryWeaver), public-domain texts, computed astrology (Skyfield + JPL), and commissioned originals. No scraping, no NC/ND, no existing recordings.
- **Languages:** all 22 + English; Tier-1 (13) via Azure Neural TTS, long tail via AI4Bharat open-source. Hard QA gate per language.
- **Voices:** 2-3 curated presets per language (pre-rendered, reused); premium voices as a subscription perk.
- **Design:** Material 3, dark-first warm theme (saffron/indigo), Noto Sans for all scripts.
- **Payments:** Store IAP in-app (15-30% cut, mandatory) + Razorpay UPI AutoPay on web (~2%, best margin).

## Honest business read

- At ~10K downloads this is a validation stage, not yet a business (realistic ~Rs 10K-45K/mo, mostly sponsorships).
- Model becomes a real business around 100K-500K downloads with concentrated language verticals.
- Differentiation/moat = content curation quality + Indian-language narration + the "radio" sequencing feel.
