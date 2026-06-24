# Language Coverage Matrix — India Interest Radio (v1)

**Goal:** Support all 22 official (8th Schedule) Indian languages + English in version 1.
**Reality:** Achievable, but via TWO TTS engines and at TWO quality tiers. No language
goes live until BOTH content and voice pass native-speaker QA (esp. devotion).

L1 speaker figures are approximate (Census 2011 order of magnitude).

---

## Full language list + readiness

| # | Language | Script | Approx L1 speakers | Commercial neural TTS | StoryWeaver content | v1 readiness |
|---|---|---|---|---|---|---|
| 1 | Hindi | Devanagari | ~52 cr | Azure + Google | Rich | Ready (Tier 1) |
| 2 | Bengali | Bengali | ~9.7 cr | Azure | Rich | Ready (Tier 1) |
| 3 | Marathi | Devanagari | ~8.3 cr | Azure | Rich | Ready (Tier 1) |
| 4 | Telugu | Telugu | ~8.1 cr | Azure | Rich | Ready (Tier 1) |
| 5 | Tamil | Tamil | ~6.9 cr | Azure | Rich | Ready (Tier 1) |
| 6 | Gujarati | Gujarati | ~5.5 cr | Azure | Rich | Ready (Tier 1) |
| 7 | Urdu | Perso-Arabic | ~5 cr | Azure | Good | Ready (Tier 1) |
| 8 | Kannada | Kannada | ~4.4 cr | Azure | Rich | Ready (Tier 1) |
| 9 | Odia | Odia | ~3.7 cr | Azure | Good | Ready (Tier 1) |
| 10 | Malayalam | Malayalam | ~3.5 cr | Azure | Rich | Ready (Tier 1) |
| 11 | Punjabi | Gurmukhi | ~3.3 cr | Azure | Good | Ready (Tier 1) |
| 12 | Assamese | Assamese | ~1.5 cr | Azure | Good | Ready (Tier 1) |
| 13 | English (India) | Latin | L2 huge | Azure + Google | Rich | Ready (Tier 1) |
| 14 | Maithili | Devanagari | ~1.35 cr | AI4Bharat only | Some | Tier 2 (open-source TTS) |
| 15 | Sanskrit | Devanagari | tiny (ritual) | AI4Bharat / limited | Some | Tier 2 (KEY for devotion) |
| 16 | Nepali | Devanagari | ~30 lakh | AI4Bharat / limited | Some | Tier 2 (open-source TTS) |
| 17 | Konkani | Devanagari | ~22 lakh | AI4Bharat only | Limited | Tier 2 (open-source TTS) |
| 18 | Sindhi | Perso-Arabic/Deva | ~27 lakh | limited | Limited | Tier 2 (open-source TTS) |
| 19 | Dogri | Devanagari | ~25 lakh | AI4Bharat only | Limited | Tier 3 (best-effort) |
| 20 | Kashmiri | Perso-Arabic | ~67 lakh | AI4Bharat only | Limited | Tier 3 (best-effort) |
| 21 | Manipuri (Meitei) | Meitei/Bengali | ~18 lakh | AI4Bharat only | Limited | Tier 3 (best-effort) |
| 22 | Bodo | Devanagari | ~15 lakh | AI4Bharat only | Limited | Tier 3 (best-effort) |
| 23 | Santali | Ol Chiki | ~73 lakh | AI4Bharat only | Limited | Tier 3 (best-effort) |

---

## Tiering + engine assignment

| Tier | Languages | TTS engine | Quality | Effort |
|---|---|---|---|---|
| Tier 1 (13) | Hindi, Bengali, Marathi, Telugu, Tamil, Gujarati, Urdu, Kannada, Odia, Malayalam, Punjabi, Assamese, English | Azure Neural TTS (commercial) | High, ship-ready | Low (API call) |
| Tier 2 (6) | Maithili, Sanskrit, Nepali, Konkani, Sindhi | AI4Bharat (IndicF5 / Indic Parler-TTS), self-hosted | Variable, needs QA | High (self-host + tune) |
| Tier 3 (5) | Dogri, Kashmiri, Manipuri, Bodo, Santali | AI4Bharat, self-hosted, best-effort | Lower, strict QA | High |

(Sanskrit appears in Tier 2 but is prioritized because devotion depends on it.)

---

## Engine notes

- **Azure Neural TTS** covers 12 Indian languages + English with high-quality neural voices,
  male/female options for major languages. Primary engine for Tier 1.
- **Google Cloud TTS** is strongest for Hindi + Indian English; weaker neural coverage for
  regional languages. Use as secondary/fallback.
- **AI4Bharat open-source** (IndicF5, Indic Parler-TTS) is purpose-built for Indian languages
  and covers the long tail Azure/Google do not. Free/self-hostable; quality varies by language
  and requires GPU hosting + tuning + QA. This is the unlock for "all 22 languages."

---

## Voice presets per tier (cost-aware)

- Tier 1 big languages (Hindi, Bengali, Tamil, Telugu, Marathi, Kannada, etc.):
  offer 2-3 presets (male_story, female_warm, devotional) where quality exists.
- Tier 1 smaller + Tier 2/3 languages: ship 1 solid voice first; add presets later.
- Do NOT generate 3 presets x 23 languages on day one (cost + QA load). Expand by demand.

---

## QA gate (hard rule — applies to every language)

A language goes live in v1 ONLY when:
- [ ] Content exists for its launched interests (kids/moral/devotion/astrology)
- [ ] Voice passes native-speaker QA (clarity, pronunciation, tone)
- [ ] Devotion pronunciation reviewed (Sanskrit/scripture especially)
- [ ] Attribution stored for all sourced content (CC BY / public domain)
- [ ] Fallback voice configured (if a preset variant is missing)

If a language fails QA, ship it as "coming soon" rather than with bad audio —
bad devotional/story audio damages trust more than a missing language.

---

## Cost note

- All 23 languages roughly TRIPLES the earlier ~7-language TTS/storage estimate.
- One-time library (1 voice, 23 langs): ~Rs 25,000-30,000 (Azure) + engineering time
  to self-host AI4Bharat for Tier 2/3.
- With 3 presets across big languages: ~Rs 75,000-90,000 one-time + higher monthly.
- Recommendation: 3 presets for Tier-1 big languages only; 1 voice for the long tail;
  expand presets by demand.

---

## v1 recommendation (summary)

- All 22 + English selectable in the app.
- Tier 1 (13) live at full Azure quality with 2-3 presets for big languages.
- Tier 2 (6) via AI4Bharat, QA'd, 1 voice (Sanskrit prioritized for devotion).
- Tier 3 (5) best-effort via AI4Bharat, strict QA, "coming soon" if not passing.
- Hard gate: no language live until content + voice pass native-speaker QA.
