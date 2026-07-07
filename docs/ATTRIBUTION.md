# Attribution Registry — Global Radio

This registry documents the license status and attribution for every content item
included in Global Radio. All items are verified public-domain or original works.

## 1. Story Content

| Item ID | Source | License | Notes |
|---------|--------|---------|-------|
| `moral-thirsty-crow` | Panchatantra | Public Domain | Ancient Indian fable, retold in our own words |
| `moral-lion-and-mouse` | Aesop's Fables | Public Domain | 6th century BCE, retold in our own words |
| `kids-clever-rabbit` | Panchatantra | Public Domain | Chameleon tale retold in our own words |
| `moral-tortoise-and-hare` | Aesop's Fables | Public Domain | Classic race fable, retold in our own words |

## 2. Devotion Content

| Item ID | Source | License | Notes |
|---------|--------|---------|-------|
| `devotion-morning-light` | Original | All rights reserved to Global Radio | Written specifically for this app |
| `devotion-evening-peace` | Original | All rights reserved to Global Radio | Written specifically for this app |

## 2a. Finance Literacy Content

| Item ID | Source | License | Notes |
|---------|--------|---------|-------|
| `finance-*` | Original | All rights reserved to Global Radio | Original financial-literacy scripts; themes inspired by RBI/SEBI investor-education campaigns, no text reused |

## 3. Astrology Content

| Item ID | Source | License | Notes |
|---------|--------|---------|-------|
| `daily-[sign]-[lang]-[date]` | Original + JPL Ephemeris | Original composition; lunar data from JPL DE421 ephemeris (public domain) | Templates are original; moon phase data computed via Skyfield |

## 3a. Daily Generated Content

| Item ID | Source | License | Notes |
|---------|--------|---------|-------|
| `gita-[ch]-[v]-[lang]-[date]` | Bhagavad Gita via [vedicscriptures.github.io](https://vedicscriptures.github.io) | Sanskrit text: public domain. English meaning: Swami Sivananda translation (public domain) | Hindi meaning is machine-translated from the Sivananda English text and labelled as such in the audio |
| `weather-[lang]-[date]` | [Open-Meteo](https://open-meteo.com) forecast API | CC BY 4.0 (data); scripts are original | 6-metro daily bulletin; templates written for Global Radio |
| `news-*` | RSS headlines: PIB (Press Information Bureau, Govt. of India), PTI-syndicated feeds and other feeds listed in `tools/content/news_sources.json` | Headlines/facts only; scripts rewritten in our own words | PIB releases are Government of India open content; we never reproduce article bodies |

## 3b. Harvested & Translated Drafts (review-gated)

All harvested items land in `tools/content/library/drafts/` with `_draft: true`
and are **never** built into audio until a human editor approves them.

| Prefix | Source | License | Notes |
|--------|--------|---------|-------|
| `ws-*` | Wikisource (per-language) | Public domain texts | Editor must verify the specific work is PD before approval |
| `wp-*` | Wikipedia (per-language) | CC BY-SA 4.0 | Approved items must credit the source article and carry the CC BY-SA notice |
| `wq-*` | Wikiquote (per-language) | Quotes: PD when the author died >60 yrs ago (India) / >70 yrs (US); compilation CC BY-SA | Editor verifies author death date before approval |
| `*-[lang]` translated | Machine translation (Google Translate via deep-translator) of our own approved items | Same license as the source item | Tagged `_machineTranslated`; approved only after a native-speaker spot check |

## 4. Audio Synthesis

- **Edge TTS**: Microsoft Edge TTS (free tier) for Hindi, English, Bengali, Marathi, Telugu, Tamil, Gujarati, Urdu, Kannada, Malayalam
- **Azure Cognitive Services**: Paid voices for Odia, Punjabi, Assamese (properly licensed via Azure subscription)

## 5. Fonts & Assets

| Asset | License | Source |
|-------|---------|--------|
| App icon | Original | Designed for Global Radio |
| UI fonts | System fonts | iOS: SF Pro; Android: Roboto |

## 6. Third-Party Libraries

See [pubspec.yaml](../global_radio/pubspec.yaml) for full Flutter dependencies.
See [requirements.txt](../global_radio/tools/requirements.txt) for Python pipeline dependencies.

All dependencies are MIT, Apache 2.0, or BSD licensed.

---

## Verification

Run `python tools/check_legal.py --all` to validate all items against the attribution schema.

Last verified: 2026-07-04
