# Technical Build Spec — India Interest Radio (Hybrid, Lightweight)

**Product:** Personalized audio "interest radio" generated from legally-safe content.
**Platforms:** iOS + Android from a single codebase.
**Constraints:** Lightweight (target < 20 MB), data-frugal (India), no audio-streaming backend.
**MVP verticals:** Kids' stories, Moral stories, Devotion, Astrology (daily).
**Languages:** English, Hindi, Kannada, Marathi, Telugu, Tamil, Bengali (expandable).

---

## 0. "Hybrid" decision (read first)

| Type | Examples | Background audio on iOS+Android | Verdict |
|---|---|---|---|
| Web-based hybrid (WebView) | Ionic, Capacitor, Cordova | Unreliable — iOS kills background/lock-screen audio | DO NOT USE |
| Compiled cross-platform | Flutter, React Native | Solid background + lock-screen | USE THIS |

Decision: **Flutter** (primary). React Native is an acceptable alternative if the team is JS-first.

---

## 1. Recommended stack (Flutter)

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter | One codebase iOS+Android, good perf, small footprint |
| Audio engine | `just_audio` + `audio_service` | Background playback, lock-screen controls, gapless queue, playlists |
| State mgmt | Riverpod | Lightweight, low boilerplate |
| Local storage | Isar or Hive (NoSQL) | Tiny/fast; stores user data + cached catalog + signals |
| HTTP | dio | Catalog fetch + caching |
| Audio cache | just_audio + flutter_cache_manager | Prefetch next item only (data saving) |

React Native equivalents: `react-native-track-player`, Zustand/Redux, MMKV/WatermelonDB, axios.

---

## 2. Architecture (layers)

```
UI (Flutter): Onboarding · Home · Player · Library · Settings
        |
RADIO ENGINE (on-device): interests -> filter -> rank -> sequence -> queue
        |
Audio Service (just_audio + audio_service): background · lock screen · gapless
        |
Data: catalog.json (cached) + user DB (Isar/Hive)
        |                              |
   fetch catalog.json on CDN     stream static MP3s on R2/CDN
```

No streaming backend. App pulls static `catalog.json`, streams pre-rendered static MP3s directly, assembles the "radio" on-device.

---

## 3. Radio Engine (core, on-device)

```
// 1. Inputs: userInterests=["kids","devotion"], userLang="kannada"
// 2. Filter
items = catalog.where(it =>
    it.language == userLang &&
    it.interests.intersects(userInterests) &&
    it.isReachable);

// 3. Score & rank
score(it) =
    interestOverlap(it, userInterests) * 0.4
  + freshness(it)                      * 0.2   // daily/new first
  + popularity(it)                     * 0.2
  + (1 - recentlyPlayed(it))           * 0.2;  // avoid repeats

// 4. Sequence for "radio" feel
queue = interleave(items_by_interest)   // rotate kids -> devotion -> kids
        .insertStingers()               // short "Next, a moral story..." intro
        .putTodaysAstrologyFirst();

// 5. Hand queue to audio_service -> continuous playback
//    On skip/complete -> log signal locally -> re-rank tail of queue
```

Personalization signals (stored locally only): completes, skips, replays, favorites, dwell time.

---

## 4. catalog.json schema (static file on CDN)

```json
{
  "version": "2026-06-23",
  "items": [
    {
      "id": "moral-thirsty-crow",
      "title": "Baayaarida Kaage",
      "interests": ["kids", "moral"],
      "language": "kannada",
      "availableVoices": ["male_story", "female_warm"],
      "defaultVoice": "male_story",
      "durationSec": 210,
      "sizeKb": 1680,
      "attribution": "Pratham Books StoryWeaver, CC BY 4.0",
      "popularity": 80,
      "type": "library"            // "library" | "daily"
    },
    {
      "id": "astro-aries-2026-06-23-hi",
      "title": "Mesh Rashi - Aaj",
      "interests": ["astrology"],
      "language": "hindi",
      "availableVoices": ["male_story", "female_warm"],
      "defaultVoice": "female_warm",
      "durationSec": 75,
      "sizeKb": 600,
      "attribution": "Generated (Skyfield + JPL ephemeris)",
      "type": "daily",
      "date": "2026-06-23",
      "sign": "aries"
    }
  ]
}
```

### Audio URL convention (voice variants)

Do NOT list every voice variant in the catalog. The app builds the URL from the
user's chosen voice preset:

```
audioUrl = https://cdn.app/{lang}/{voiceId}/{itemId}.mp3
e.g. voiceId="female_warm", lang="kannada":
     https://cdn.app/kannada/female_warm/moral-thirsty-crow.mp3
```

- App stores `preferredVoice` locally (global or per-interest setting).
- If chosen voice is not in `availableVoices` for an item -> fall back to `defaultVoice` (never break playback).

---

## 5. Minimal backend-lite (NOT a streaming server)

| Need | Service | Cost |
|---|---|---|
| Host catalog.json + MP3s | Cloudflare R2 (zero egress) | ~Rs 100/mo |
| Auth + profile/prefs | Firebase Auth + Firestore (free tier) | Rs 0 to start |
| Daily astrology job | Cloud Function/cron: compute -> generate text -> TTS -> upload | ~Rs 500/mo |
| Push notifications | Firebase Cloud Messaging | Rs 0 |

Data stored = user profile + preferences + favorites + consent ONLY. No third-party audio relayed/hosted.

---

## 6. Daily astrology pipeline

```
cron (daily 00:30 IST):
  for sign in 12 signs:
     positions = Skyfield(JPL_ephemeris).compute(sign, today)   // MIT + PD data
     text_en  = generate_reading(positions)                     // template/LLM
     for lang in [hi, kn, mr, te, ta, bn, en]:
        text = translate_or_template(text_en, lang)
        mp3  = TTS(text, voice[lang])                            // pre-render once
        upload(mp3 -> R2)
  append entries to catalog.json (type:"daily", date)
  send FCM "Today's horoscope is ready"
```

Reuse across all users (compute once per sign/lang/day). Avoid Swiss Ephemeris (AGPL/commercial); use Skyfield (MIT) + NASA JPL DE ephemeris (public domain).

---

## 7. Voice selection (user-chosen narration voice)

Principle: keep "pre-render once, reuse for all users" by offering a CURATED SET
of voice presets per language (NOT unlimited custom voices).

### Approach comparison

| Approach | TTS/storage cost | Latency | Backend? |
|---|---|---|---|
| 1 fixed voice | x1 | instant | No |
| Curated presets (2-3/lang) -- USE THIS | x2-3 (still cheap) | instant | No |
| Fully custom / any accent per user | xN (explodes) | slow (gen on play) | Yes |

### Voice presets (per language, only where quality exists)

| Preset id | Description | Use |
|---|---|---|
| `male_story` | Male, storyteller | moral/kids |
| `female_warm` | Female, warm | kids/romance |
| `devotional` | Calm, reverent | devotion |
| (optional) regional accent variant | where good voices exist | regional |

Note: not every Indian language has good male AND female neural voices. Offer
presets only where per-language quality is verified. Test before promising.

### Cost impact (1 voice vs 3 presets)

| | 1 voice | 3 presets |
|---|---|---|
| One-time TTS library (~6.4M chars) | ~Rs 8,700 | ~Rs 26,000 |
| Astrology recurring/mo | ~Rs 3,100 | ~Rs 9,300 |
| Storage (R2) | ~Rs 100 | ~Rs 300 |

### Providers for voice variety

| Provider | Variety | Cost | Best for |
|---|---|---|---|
| Google Cloud TTS | Indian voices, M/F | ~$16/1M chars | Default library |
| Azure Neural TTS | Indian voices + styles | ~$16/1M | Tone variety |
| ElevenLabs | Best quality, custom, accents | High per-char | Premium tier only |
| On-device TTS | M/F sometimes, lower quality | Free | Cheap fallback |

### Monetization tie-in

- Free tier: 1 default voice per language.
- Premium ("remove ads" / Rs 99/yr): unlock ALL presets + 1 high-quality
  (ElevenLabs) voice + accent options. Makes the cheap subscription tangible.

### Later (optional): true custom voices

Premium "generate-on-first-play-then-cache" model: generate a variant once on
first request by a premium user, store it, reuse after. Contains cost while
feeling unlimited. Build only after preset demand is proven.

---

## 8. Lightweight + data-frugal tactics (India)

App size (target < 20 MB):
- Flutter App Bundle / `--split-per-abi` (download only the user's CPU slice)
- No bundled audio — all streamed/cached on demand
- Minimal dependencies; tree-shake fonts/icons

Data saving:
- Speech audio at 64 kbps mono (~0.5 MB/min); "low-data mode" 48 kbps
- Prefetch only the NEXT 1 item, not the whole queue
- Cache played items locally for instant replay + offline favorites
- Catalog fetched once/day, cached, delta-updated via `version`

Performance:
- Lazy-render + paginate lists
- Warm-start player; preload first item during onboarding

---

## 9. Screens (MVP = 5)

1. Onboarding — pick interests + language (seeds the radio)
2. Home — "Your Stations" (per interest mix) + "Today" (astrology/daily)
3. Player — play/skip/favorite, "why this", lock-screen controls
4. Library — favorites + recently played (offline-capable)
5. Settings — language, **voice preset**, low-data mode, account, privacy

---

## 10. Build effort (1-2 devs)

| Phase | Scope | Effort |
|---|---|---|
| 1 | Flutter shell + audio service + onboarding | 2-3 weeks |
| 2 | Radio engine + catalog + player | 3-4 weeks |
| 3 | Astrology daily pipeline + content load | 2-3 weeks |
| 4 | Caching, low-data, polish, store submission | 2-3 weeks |
| MVP | Both platforms, one codebase | ~9-13 weeks |

---

## 11. Platform/cost notes

- Apple Developer Program: $99/year. Google Play: $25 one-time.
- Verify TTS provider terms allow commercial distribution of generated audio (Google/Azure/Polly: yes).
- iOS background audio: set `UIBackgroundModes: audio`; configure `audio_service` for both platforms.
- Privacy policy + terms required before store submission (also for storing user data).

---

## 12. Definition of done (technical launch gate)

- [ ] Background + lock-screen audio works on real iOS and Android devices
- [ ] App size < 20 MB (per-ABI)
- [ ] Catalog cached + delta-updates; works on first slow connection
- [ ] Low-data mode verified (<= 0.5 MB/min)
- [ ] On-device personalization (skips/completes) influences queue
- [ ] Voice preset selectable; missing variant falls back to default without breaking playback
- [ ] Daily astrology job runs unattended and publishes all signs x languages
- [ ] Offline favorites play with no network
- [ ] Privacy policy, terms, account deletion present
