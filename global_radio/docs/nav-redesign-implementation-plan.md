# Navigation Redesign Implementation Plan

## Overview
Redesign from 3-tab to 4-tab navigation with improved mini-player.

**Current:** Home | Library | Settings
**New:** Listen | Today | Saved | You

---

## Phase 1: Foundation (Infrastructure)
*Estimated: 1 hour*

### 1.1 Create Today Screen Structure
- [ ] Create `lib/features/today/today_screen.dart`
- [ ] Create `lib/features/today/today_provider.dart` (combines astrology, festivals, streaks)
- [ ] Create `lib/features/today/widgets/` folder for sub-components

### 1.2 Update Router
- [ ] Add `/today` branch to `StatefulShellRoute` in `lib/core/router.dart`
- [ ] Reorder branches: `/home` → `/today` → `/library` → `/settings`
- [ ] Keep all existing standalone routes (`/player`, `/signin`, etc.)

### 1.3 Update ScaffoldWithNav
- [ ] Update `lib/shared/widgets/scaffold_with_nav.dart` with 4 destinations
- [ ] New icons: `headphones_rounded`, `wb_sunny`, `bookmarks`, `person`
- [ ] New labels: Listen, Today, Saved, You

---

## Phase 2: Today Screen (New Tab)
*Estimated: 2 hours*

### 2.1 Today Screen Content
- [ ] Date header with moon phase (from astrology data if available)
- [ ] Zodiac sign selector (12 signs as horizontal chips)
- [ ] Today's astrology card (large, prominent) 
- [ ] Morning show card (if content exists) - uses `morning_show_provider.dart`
- [ ] Daily festival card - uses `festival_provider.dart`
- [ ] Streak counter widget - uses `streaks_service.dart`

### 2.2 Today Provider
- [ ] Combine data from:
  - `catalogProvider` (filter `isDaily` items for today)
  - `relevantFestivalsProvider`
  - `dailyShowProvider`
  - `currentStreakProvider`
- [ ] Create `todayContentProvider` that aggregates all daily content

### 2.3 Deep Link Support
- [ ] Update FCM push handler to navigate to `/today`
- [ ] Handle `data: {"type": "daily_astrology", ...}` payload

---

## Phase 3: Mini-Player Redesign
*Estimated: 1.5 hours*

### 3.1 Progress Bar
- [ ] Add `StreamProvider` for playback position from `audioHandlerProvider`
- [ ] Add 2px progress bar at top of mini-player
- [ ] Use `scheme.primary` color (saffron/gold)

### 3.2 Voice Badge
- [ ] Show compact voice preset pill: "🧒 Kids" or "🪔 Dev"
- [ ] Position between title and play button
- [ ] Max 4 characters + emoji

### 3.3 Waveform Animation
- [ ] Create `_WaveformIndicator` widget with 3 animated bars
- [ ] Show when playing, freeze when paused
- [ ] Replace static interest icon when audio is active

### 3.4 Layout Optimization
- [ ] Keep 64px height constraint
- [ ] Title: single line only with ellipsis
- [ ] Remove subtitle (interest label) to make room for voice badge

---

## Phase 4: Listen Screen (Refactor Home)
*Estimated: 45 mins*

### 4.1 Remove Today Section
- [ ] Remove "Today" horizontal scroll strip from `home_screen.dart`
- [ ] That content now lives in Today tab

### 4.2 Focus on Radio
- [ ] Keep "Play Radio" CTA card at top
- [ ] Keep "Your Stations" interest cards below
- [ ] Add "Now Playing" state when radio is active (replace play card)
- [ ] Optional: Add waveform animation to Now Playing state

### 4.3 Rename/Update
- [ ] Optionally rename file to `listen_screen.dart` (or keep `home_screen.dart`)
- [ ] Update AppBar title: "Listen" or keep personalized greeting

---

## Phase 5: Saved Screen (Refactor Library)
*Estimated: 1 hour*

### 5.1 Remove Inner TabBar
- [ ] Remove `DefaultTabController` and `TabBarView` from `library_screen.dart`
- [ ] Replace with single `ListView` with section headers

### 5.2 Add Downloads Section
- [ ] Import from `downloads_screen.dart` or create summary widget
- [ ] Show offline-available items with size badge
- [ ] Link to full downloads management

### 5.3 Section Structure
```
- Favorites (Section header)
  - [List of favorited items]
- Recently Played (Section header)  
  - [Last 20 items]
- Downloads (Section header)
  - [Offline items with size]
```

### 5.4 Rename/Update
- [ ] Rename file to `saved_screen.dart` (or keep `library_screen.dart`)
- [ ] Update AppBar title: "Saved"

---

## Phase 6: You Screen (Refactor Settings)
*Estimated: 1 hour*

### 6.1 Add Profile Header
- [ ] Move greeting from Home AppBar to this screen
- [ ] Large avatar + name at top
- [ ] Premium badge if applicable

### 6.2 Quick Settings Surface
- [ ] Voice preset quick-switch (most changed setting)
- [ ] Language + Interests links
- [ ] Premium upsell/status

### 6.3 Reorganize Sections
```
- [Avatar + Name Header]
- Voice (quick switch)
- Language & Interests
- Premium Status
- Data & Storage
  - Low-data toggle
  - Downloads summary
- Account
  - Sign in/out
  - Delete account
- Legal
  - Privacy Policy
  - Terms of Service
```

### 6.4 Rename/Update
- [ ] Rename file to `you_screen.dart` (or keep `settings_screen.dart`)
- [ ] Update AppBar title: "You"

---

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `lib/core/router.dart` | MODIFY | Add `/today` branch, reorder |
| `lib/shared/widgets/scaffold_with_nav.dart` | MODIFY | 4 tabs with new icons/labels |
| `lib/shared/widgets/mini_player.dart` | MODIFY | Progress bar, voice badge, waveform |
| `lib/features/today/today_screen.dart` | CREATE | New Today tab screen |
| `lib/features/today/today_provider.dart` | CREATE | Aggregates daily content |
| `lib/features/today/widgets/` | CREATE | Today screen widgets |
| `lib/features/home/home_screen.dart` | MODIFY | Remove Today section, focus on radio |
| `lib/features/library/library_screen.dart` | MODIFY | Remove tabs, add Downloads section |
| `lib/features/settings/settings_screen.dart` | MODIFY | Add profile header, reorg |
| FCM push handler | MODIFY | Deep link to `/today` |

---

## Testing Checklist

### Navigation
- [ ] All 4 tabs navigate correctly
- [ ] Tab state is preserved when switching
- [ ] Deep link to `/today` works from FCM notification
- [ ] `/player` full-screen route still works from mini-player tap

### Mini-Player
- [ ] Progress bar updates in real-time
- [ ] Voice badge shows correct preset
- [ ] Waveform animates when playing, freezes on pause
- [ ] Tap opens full player
- [ ] Play/pause button works
- [ ] Skip next button works

### Today Screen
- [ ] Shows today's astrology for selected sign
- [ ] Shows festivals if any today
- [ ] Shows streak count
- [ ] Tapping astrology card plays content

### Saved Screen
- [ ] Favorites section shows hearted items
- [ ] Recently played shows last 20
- [ ] Downloads section shows offline items
- [ ] All items are playable

### You Screen
- [ ] Profile header shows name + avatar
- [ ] Voice quick-switch works
- [ ] All settings functional
- [ ] Sign in/out works

---

## Implementation Order (Recommended)

1. **scaffold_with_nav.dart** - Update to 4 tabs (breaks routing temporarily)
2. **router.dart** - Add `/today` branch (fixes routing)
3. **today_screen.dart** - Create basic Today screen
4. **mini_player.dart** - Add progress bar + voice badge + waveform
5. **home_screen.dart** - Remove Today section
6. **library_screen.dart** - Flatten to sections, add Downloads
7. **settings_screen.dart** - Add profile header, reorganize
8. **FCM handler** - Deep link support

---

## Dependencies Between Tasks

```
scaffold_with_nav.dart ──┐
                         ├──► App compiles with 4 tabs
router.dart ─────────────┘

today_screen.dart ◄─── Uses existing providers:
  ├── catalogProvider (daily items)
  ├── relevantFestivalsProvider
  ├── dailyShowProvider  
  └── currentStreakProvider

mini_player.dart ◄─── Uses existing:
  ├── radioControllerProvider
  ├── audioHandlerProvider.positionStream
  └── profileProvider.preferredVoice
```

---

## Risk Areas

1. **Tab index mismatch** - Router branches must match NavigationBar destinations order exactly
2. **Mini-player height** - Adding progress bar + voice badge must stay within 64px
3. **FCM deep link** - App must handle notification tap when app is cold/warm/hot
4. **Downloads integration** - May need to expose `downloadedItemsProvider` from downloads feature

---

## Estimated Total Time: ~7 hours

- Phase 1 (Foundation): 1 hour
- Phase 2 (Today): 2 hours  
- Phase 3 (Mini-Player): 1.5 hours
- Phase 4 (Listen): 45 mins
- Phase 5 (Saved): 1 hour
- Phase 6 (You): 1 hour
