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

## 3. Astrology Content

| Item ID | Source | License | Notes |
|---------|--------|---------|-------|
| `daily-[sign]-[lang]-[date]` | Original + JPL Ephemeris | Original composition; lunar data from JPL DE421 ephemeris (public domain) | Templates are original; moon phase data computed via Skyfield |

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

Last verified: 2025-01-01
