# GlobalRadio — Engagement Strategy

*Prepared 2026-07-04 · pairs with `launch-and-revenue-plan.md` and `ads-placement-strategy.md`*

Goal: make daily listening a **habit**, not a discovery. North-star metric: **DAU/MAU ≥ 35%** with **≥ 12 listening minutes/day** by D90 post-launch.

> **Implementation status (2026-07-04): all four phases SHIPPED** in `lib/features/engagement/` —
> streak-rescue notification (id 7101, next-day 19:00), personal push time (on-device habitual-hour
> median, id 7102, habit−15 min), day-2 hook (id 7103, 07:30), milestone confetti + share card
> (3/7/30/100/365), serialized journeys (Panchatantra 12-part + Paisa Ki Pathshala 6-day,
> metadata-only, daily unlock), daily mystery slot (date-seeded, deterministic), weekly goal
> (5-of-7, RC-tunable), voting-loop closer card, real listener counts (`listener_counts_json` RC →
> festival card with simulated fallback), Android home widget (native `NowPlayingWidgetProvider`),
> festival day-of + rashi win-back push tooling (`tools/festival_push.py`), analytics events
> (`engagement_nudge`, `milestone_reached`, `journey_progress`, `mystery_reveal`, `weekly_goal_met`).
> Guardrails enforced in code: quiet hours 22:00–07:00 clamp on every local notification, nothing
> fires in Kids Mode, every mechanic behind its own `engage_*` Remote Config kill switch.

---

## 1. Where we stand — engagement asset inventory

What the app already has (all shipped, all tested):

| Loop stage | Asset | State |
|---|---|---|
| **Trigger** | Daily-astrology FCM push (topic-based, server cron) | Broadcast only, same time for everyone |
| | Smart alarm (local notification, wake to your radio) | Opt-in in Settings |
| | Festival live cards (Today tab) | Listener count is simulated |
| **Action** | Today tab (astrology + festivals + streaks) — the habit driver | Live |
| | Morning brief, morning show, news brief | Fresh daily via pipeline |
| | Continue-listening resume card | Live |
| | One-tap radio sequenced by daypart | Core product |
| **Reward** | Streaks (current/longest, at-risk visual state) | Displayed, never *celebrated* |
| | Weekly insights + share card | Live |
| **Investment** | Interests, saved items, offline packs, read-along, referral + gift codes, voting/listeners' choice | Live |

Strong foundation. The gaps are all in **closing the loop** — the assets exist but don't talk to each other.

## 2. Gap analysis — why users would lapse today

1. **Triggers aren't personal.** The astrology push fires at one global time. A user who listens at 9 PM gets a 7 AM push — wasted. No push references *their* streak, *their* rashi, *their* unfinished story.
2. **Streak at risk is silent.** `isStreakAtRisk` exists in code and turns the badge red — but the user only sees it if they *already opened the app*. That's backwards: the at-risk moment is exactly when they're **not** in the app.
3. **No celebration.** Hitting 7/30/100 days looks identical to day 2. Milestones are the cheapest dopamine we're not paying.
4. **Content is all single-shot.** Nothing says "come back tomorrow for part 2". Serialized stories are the oldest retention trick in radio — we have Panchatantra/folk material that naturally chains.
5. **Session ends dead.** When the queue finishes there's no "tomorrow on your radio…" teaser. Every session ending is an unbooked next appointment.
6. **No variable reward.** The radio is (deliberately) predictable. One small daily surprise slot would add the slot-machine pull without hurting trust.
7. **Social proof is fake or absent.** Festival listener counts are simulated; nothing shows "12,000 people heard this story today in Tamil".
8. **No win-back.** A user gone 7 days hears nothing from us, ever again.
9. **Home-screen widget** is documented (`docs/WIDGET_SETUP.md`) but not shipped — the highest-CTR trigger surface on Android.

## 3. The plan — four phases

Everything ships behind Remote Config flags (same discipline as ads). No engagement mechanic may fire in Kids Mode.

### Phase 1 — Close the daily loop (pre-launch / launch week, low effort)

| # | Feature | Mechanic | Effort |
|---|---|---|---|
| 1.1 | **Streak-rescue notification** | Local notification at ~19:00 if `isStreakAtRisk` and no listen today: "🔥 Your 12-day streak ends at midnight — 2 minutes keeps it alive." Deep-links to Play. | S |
| 1.2 | **Personal push time** | Record the user's habitual listen hour (rolling median of session starts, on-device). Schedule the daily astrology/brief nudge as a *local* notification at `habit_hour − 15 min`. Falls back to FCM topic time. | S |
| 1.3 | **Milestone celebrations** | Full-screen confetti + shareable card at 3, 7, 30, 100, 365-day streaks. Share card = organic acquisition. | S |
| 1.4 | **Day-2 hook** | Last onboarding screen + end of first session: "Your rashi's reading for tomorrow will be ready at sunrise 🌅". Sets the first return appointment. | XS |
| 1.5 | **"Tomorrow on your radio" outro** | When the queue ends, a 10-second TTS outro teasing tomorrow's fresh items (pipeline already knows). | M |

**Remote Config keys:** `engage_streak_rescue_enabled`, `engage_personal_push_enabled`, `engage_milestones_enabled`, `engage_outro_teaser_enabled`.

### Phase 2 — Appointment content (weeks 2–6)

| # | Feature | Mechanic | Effort |
|---|---|---|---|
| 2.1 | **Serialized journeys** | Chain existing catalog items into series with a daily-unlock gate: "Panchatantra, episode 4 of 12 — new episode tomorrow". Metadata-only change (`series_id`, `episode_n`) + a Journey card on Today. Start with: 12-part Panchatantra, 7-day finance basics, 9-day Gita walk. | M |
| 2.2 | **Daily surprise slot** | One "mystery story" item per day in the radio — revealed only when it plays. Variable reward, zero new content cost. | S |
| 2.3 | **Weekly listening goal** | Soft goal (e.g., 5 of 7 days) shown on the streak card; completing it upgrades the weekly share card. | S |
| 2.4 | **Close the voting loop** | Listeners' choice already collects votes — announce the winner in Sunday's morning show + a push: "Your votes chose tonight's story." | S |

### Phase 3 — Social proof & surfaces (month 2–3)

| # | Feature | Mechanic | Effort |
|---|---|---|---|
| 3.1 | **Real listener counts** | Replace simulated festival counts with real daily aggregates from analytics (server-side count, Remote Config-fed JSON, no new backend). "🎧 14,203 heard this today in हिन्दी". | M |
| 3.2 | **Android home-screen widget** | Ship the documented widget: today's rashi line + play button + streak flame. Widgets lift D30 retention materially on Android-heavy markets like India. | M |
| 3.3 | **Win-back campaigns** | FCM to lapsed segments (7/21-day inactive) with the strongest hook we have — their rashi: "Mesh, your stars have been busy this week…". Max 1/week, auto-stop after 3 unanswered. | M |
| 3.4 | **Festival event pushes** | Pipeline already knows the festival calendar — day-of push: "Diwali special is live: Lakshmi aarti + stories 🪔". | S |

### Phase 4 — Measure & iterate (continuous)

- **Metrics tree:** DAU/MAU → (D1, D7, D30 retention) → sessions/day → minutes/session → completion rate per category.
- **Per-mechanic events:** every notification logs sent/opened/converted-to-listen; every journey logs episode-completion funnel.
- **A/B everything** via Firebase: push copy, send time offset, milestone thresholds, surprise-slot frequency.
- **Guardrails:** notification opt-out rate < 8%, uninstall-within-24h-of-push < 0.5%, no mechanic ships to Kids Mode, bedtime hours (22:00–07:00) are push-silent. Any breach → flag off remotely.

## 4. Prioritization (impact × effort)

```
        HIGH IMPACT
            │
  1.1 🔥    │    2.1 📚
  1.2 ⏰    │    3.2 📱
  1.3 🎉    │    3.1 👥
  1.4 🌅    │    3.3 🔁
────────────┼──────────── EFFORT →
  2.2 🎁    │    1.5 🗣
  2.3 🎯    │    3.4 🪔
  2.4 🗳    │
            │
        LOW IMPACT
```

**Do first (this week):** 1.1 streak rescue, 1.2 personal push time, 1.3 milestones, 1.4 day-2 hook — all reuse existing streak/notification plumbing, all size S or XS, and together they close the trigger→reward loop that's currently open.

## 5. Why this fits *this* app

- **Astrology is a natural daily appointment** — the content expires every 24h. Nothing to invent; just deliver it at the right personal moment.
- **The India context rewards streaks + festivals**: the app already tracks both; we only add the celebration and the push.
- **Radio serialization is a century-old habit mechanic** and our folk-tale catalog chains for free.
- **Everything is a flag**: like the ads system, every mechanic can be tuned or killed from Remote Config without a release.

---

*Checklist owner: PM. Review after 4 weeks of launch data — kill anything whose notification opt-out or uninstall guardrail trips.*
