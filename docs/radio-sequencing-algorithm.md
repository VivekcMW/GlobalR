# On-Device Radio Sequencing Algorithm

How selected interests become a continuous, personalized "radio" — entirely on the
phone. No streaming backend; operates over the cached `catalog.json` + local signals.

---

## 0. Inputs and stored state

```
USER PROFILE (local, Isar/Hive):
  languages:        ["hindi", "kannada"]
  interests:        ["kids", "moral", "devotion", "astrology"]
  preferredVoice:   "female_warm"
  lowDataMode:      false
  isPremium:        false

LOCAL SIGNALS (per item, updated as user listens):
  playCount, completeCount, skipCount, lastPlayedAt, favorited(bool), dwellMs

CATALOG (cached from CDN, refreshed daily):
  items[]: { id, interests[], language, availableVoices[], defaultVoice,
             durationSec, sizeKb, popularity, type("library"|"daily"), date, sign }
```

---

## 1. Top-level flow

```
buildRadio(profile, catalog, signals):
    pool      = filter(catalog, profile)
    scored    = [ (item, score(item, profile, signals)) for item in pool ]
    ranked    = sortDescending(scored by score)
    queue     = sequence(ranked, profile)      // interleave + daily-first + stingers
    return queue
```

The queue is lazy: build the first ~10 items, extend as the user listens.

---

## 2. Filter

```
filter(catalog, profile):
    return [ it for it in catalog if
                it.language in profile.languages
            and intersects(it.interests, profile.interests)
            and isReachable(it)                 // last health-check passed
            and not isBlocked(it) ]
```

`isReachable` uses a cached health flag (a tiny periodic checker hides dead URLs).

---

## 3. Scoring

```
score(it, profile, signals):
    s = signals[it.id]

    interestScore  = overlapCount(it.interests, profile.interests)
                     / count(profile.interests)            // 0..1
    freshness      = freshnessBoost(it)                    // daily/new -> high
    popularity     = it.popularity / 100.0                 // 0..1
    noveltyPenalty = recencyPenalty(s.lastPlayedAt)        // recently played -> low
    affinity       = affinityBoost(s)                      // learned taste 0..1
    favoriteBoost  = s.favorited ? 0.15 : 0.0

    return  0.35 * interestScore
          + 0.20 * freshness
          + 0.15 * popularity
          + 0.20 * affinity
          - 0.25 * noveltyPenalty
          + favoriteBoost
```

### Helper definitions

```
freshnessBoost(it):
    if it.type == "daily" and it.date == today:  return 1.0   // today's horoscope/story
    ageDays = today - it.publishedDate
    return clamp(1.0 - ageDays/90.0, 0.0, 1.0)

recencyPenalty(lastPlayedAt):
    if lastPlayedAt == null:        return 0.0
    hours = now - lastPlayedAt
    if hours < 6:    return 1.0     // just heard it -> strongly avoid
    if hours < 24:   return 0.6
    if hours < 72:   return 0.3
    return 0.0

affinityBoost(s):
    // reward completes, punish skips (learned taste)
    plays = max(s.playCount, 1)
    completeRate = s.completeCount / plays      // 0..1
    skipRate     = s.skipCount / plays          // 0..1
    return clamp(0.5 + 0.5*completeRate - 0.5*skipRate, 0.0, 1.0)
```

Premium users: no ad items inserted; free users get ad markers (see section 6).

---

## 4. Sequencing (the "radio feel")

Ranking alone feels like a playlist. Sequencing makes it feel like radio.

```
sequence(ranked, profile):
    queue = []

    // (a) Lead with today's daily content (horoscope / daily story)
    daily = takeWhere(ranked, it -> it.type == "daily" and it.date == today)
    queue += capPerInterest(daily, maxPerInterest = 1)

    // (b) Interleave by interest so one topic doesn't dominate (round-robin)
    buckets = groupByInterest(remaining(ranked), profile.interests)
    while anyNonEmpty(buckets):
        for interest in rotateOrder(profile.interests):   // rotate to vary order
            it = popHighest(buckets[interest])
            if it != null and not violatesConstraints(queue, it):
                queue.append(it)

    // (c) Insert short spoken "stingers" between items for radio texture
    queue = insertStingers(queue, profile)   // "Aage suniye ek naitik kahani..."

    return queue
```

### Constraints to keep it pleasant

```
violatesConstraints(queue, it):
    last3 = tail(queue, 3)
    // avoid 3 same-interest in a row
    if all(x.interest == it.interest for x in last3):  return true
    // avoid same item twice within a session
    if it.id in idsOf(queue):                          return true
    // avoid two long items back-to-back in low-data/short-attention
    if last(queue)?.durationSec > 600 and it.durationSec > 600: return true
    return false
```

### Stingers (optional, premium-feel)

```
insertStingers(queue, profile):
    out = []
    for it in queue:
        out.append( stingerFor(it.interest, profile.languages[0]) )  // tiny pre-roll
        out.append(it)
    return out
// stingers are pre-rendered tiny audio clips per interest per language
```

---

## 5. Live re-ranking (reacting to behavior)

```
onPlaybackEvent(event, item):
    updateSignals(item, event)        // play/complete/skip/dwell
    if event == SKIP:
        // user disliked -> demote this interest/voice slightly for the session
        sessionBias[item.interest] -= 0.1
        rerankTail(queue, fromIndex = currentIndex + 1)
    if event == COMPLETE:
        sessionBias[item.interest] += 0.05
    persistSignals()                  // local DB only
```

Only the *tail* of the queue is re-ranked (cheap), never the already-played part.

---

## 6. Ads + prefetch (free tier + data discipline)

```
maybeInsertAd(queue, profile):
    if profile.isPremium: return queue
    everyNItems = 4
    insert adMarker after each 'everyNItems' content items
    return queue

prefetchPolicy:
    // data-frugal: only fetch the NEXT item's audio
    prefetch(queue[currentIndex + 1].audioUrlFor(profile.preferredVoice))
    if lowDataMode: use 48kbps variant else 64kbps
```

---

## 7. Voice resolution (per item)

```
audioUrlFor(item, profile):
    voice = profile.preferredVoice
    if voice not in item.availableVoices:
        voice = item.defaultVoice            // never break playback
    return "https://cdn.app/{item.language}/{voice}/{item.id}.mp3"
```

---

## 8. Cold start (brand-new user, no signals)

```
coldStart(profile, catalog):
    // no affinity yet -> lean on popularity + freshness + interest match
    score = 0.45*interestScore + 0.30*popularity + 0.25*freshness
    // ensure variety: at least 1 item per selected interest in first 5
    guaranteeCoverage(queue, profile.interests, within = 5)
```

---

## 9. Complexity / performance

- Filter + score: O(N) over cached catalog (N = items for user's languages; small).
- Sort: O(N log N), done once per refresh; tail re-rank is O(k).
- All in-memory over a cached JSON; no network in the hot path except next-item prefetch.
- Target: build first 10 queue items in < 50 ms on a low-end Android device.

---

## 10. Tunable weights (ship as remote config)

| Weight | Default | Lever |
|---|---|---|
| interest | 0.35 | relevance vs variety |
| freshness | 0.20 | how much daily/new is pushed |
| popularity | 0.15 | safe/known vs niche |
| affinity | 0.20 | personalization strength |
| noveltyPenalty | 0.25 | repeat avoidance |
| favoriteBoost | 0.15 | favorites stickiness |
| adEveryN | 4 | ad load (free tier) |

Expose via Firebase Remote Config so you can tune retention without an app update.
