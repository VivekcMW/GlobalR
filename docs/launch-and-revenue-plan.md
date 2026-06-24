# 12-Month India Launch + Revenue Plan

Honest, staged plan to go from zero to a validated, monetizing audio app in India.
Numbers are realistic (conservative-base), not investor-deck optimism.

Core strategy: WIN A NICHE FIRST. Do not launch "all interests x 22 languages" loud
on day one. Concentrate, prove retention + willingness-to-pay, then widen.

---

## Guiding principles

1. Value before signup; radio plays in the first ~5 seconds.
2. Concentrate language + interest early (depth beats breadth at small scale).
3. Lead monetization with SPONSORSHIPS + content prioritization, not the Rs 9 sub.
4. Subscription = "remove ads + premium voices + offline" at Rs 99/year (web/UPI preferred).
5. Retention is the only metric that matters first. Revenue follows retention.

---

## Phase 0 — Pre-launch (Month 0, ~4-6 weeks)

Build + content + legal groundwork (overlaps with the technical build).

- [ ] Flutter shell + audio service + onboarding + radio engine (per tech spec)
- [ ] Catalog pipeline + Cloudflare R2 + Firebase
- [ ] Content: 50 kids + 50 moral + 30 devotion + daily astrology, in 3 LAUNCH languages
- [ ] Launch languages: Hindi + 2 regional (recommend Tamil + Marathi OR Telugu + Kannada)
- [ ] 2-3 voice presets for launch languages (QA'd)
- [ ] Legal checklist cleared (attribution, privacy, terms, takedown)
- [ ] Landing page + Play Store listing assets
- Gate to launch: background audio works on real devices; Day-1 experience delightful.

KPIs: n/a (build phase).

---

## Phase 1 — Soft launch (Months 1-2)

Android-only, 3 languages, invite/organic. Goal = retention signal, not growth.

Activities:
- [ ] Android release (App Bundle, < 20 MB)
- [ ] Seed 500-2,000 installs via communities (regional FB/WhatsApp groups, temples,
      schools, parenting + devotional groups)
- [ ] Instrument funnel (install -> activate -> D1 -> D7 -> D30)
- [ ] Weekly content additions (keep daily astrology + 1-2 new stories/day)
- [ ] Talk to 20+ users (what they love / skip)

Targets:
| Metric | Target |
|---|---|
| Installs | 2,000-5,000 |
| Activation (pick interests + play) | >= 45% |
| D7 retention | >= 20% |
| D30 retention | >= 12-15% |

Revenue: ~Rs 0 (focus on product). Maybe 1 pilot sponsor (free/discounted).

GO/NO-GO GATE: If D30 < 10%, FIX RETENTION before spending on growth or adding languages.

---

## Phase 2 — Monetization pilot (Months 3-4)

Turn on ads + first real sponsorships + soft subscription. ~10K downloads target.

Activities:
- [ ] Integrate ad SDK (audio + display); cap frequency (every ~4 items)
- [ ] Launch Rs 99/year premium (web Razorpay/UPI + store IAP); free = ads
- [ ] Sign 1-2 regional sponsors for an interest channel (devotional/kids)
- [ ] Add content prioritization (paid featured placement, capped)
- [ ] iOS build begins

Targets:
| Metric | Target |
|---|---|
| Cumulative installs | ~10,000 |
| MAU | ~3,000 |
| Sub conversion (of MAU) | 1-2% (30-60 subs) |
| Monthly revenue | Rs 10,000-45,000 (mostly sponsorship) |

Revenue mix (realistic, from earlier model):
| Stream | Conservative | Optimistic |
|---|---|---|
| Subscription (Rs 99/yr) | Rs 200 | Rs 600 |
| Ads | Rs 3,000 | Rs 8,000 |
| Sponsorship | Rs 5,000 | Rs 25,000 |
| Content prioritization | Rs 2,000 | Rs 12,000 |
| Total / month | ~Rs 10,000 | ~Rs 45,000 |

Infra cost: ~Rs 13,000-22,000/month -> roughly breakeven if 1-2 sponsors land.

---

## Phase 3 — Expand languages + verticals (Months 5-8)

Now widen, because retention is proven. iOS live. Add Tier-1 languages + new interests.

Activities:
- [ ] iOS launch (both platforms live)
- [ ] Add remaining Tier-1 languages (Bengali, Telugu/Kannada, Gujarati, Malayalam, etc.)
- [ ] Add Romantic + Moral expansion + Marriage advice (commissioned content)
- [ ] Begin AI4Bharat self-hosting for Tier-2/3 long-tail languages
- [ ] Push notifications for daily habit (horoscope/story ready)
- [ ] Referral loop ("share this story/station")
- [ ] Light paid UA test (small budget, measure CAC vs retention)

Targets:
| Metric | Target |
|---|---|
| Cumulative installs | 50,000-100,000 |
| MAU | 15,000-30,000 |
| Sub conversion | 1.5-2.5% |
| Monthly revenue | Rs 1.5L-6L |

Infra cost: ~Rs 40,000-70,000/month. Margin improves (content reused across users).

---

## Phase 4 — Scale + sponsorship engine (Months 9-12)

Build a repeatable ad-sales / sponsorship motion; cover all 22 languages.

Activities:
- [ ] Complete all 22 + English (Tier-2/3 via AI4Bharat, QA-gated)
- [ ] Dedicated sponsorship kit + direct sales to regional/devotional/education brands
- [ ] Premium voice tier (ElevenLabs high-quality voice) as paid perk
- [ ] Family plan; annual-first pricing to cut churn
- [ ] Optimize ad fill + eCPM (mediation)
- [ ] Evaluate web player (SEO discovery) if data justifies

Targets (end of Year 1):
| Metric | Conservative | Optimistic |
|---|---|---|
| Cumulative installs | 100,000 | 300,000 |
| MAU | 30,000 | 90,000 |
| Sub conversion | 2% | 3% |
| Monthly revenue | Rs 1.5L | Rs 6L+ |

---

## Year-1 revenue trajectory (summary)

| Phase | Months | Installs (cum) | MAU | Monthly revenue |
|---|---|---|---|---|
| 1 Soft launch | 1-2 | 2-5K | 1-2K | ~Rs 0 |
| 2 Monetization pilot | 3-4 | ~10K | ~3K | Rs 10-45K |
| 3 Expand | 5-8 | 50-100K | 15-30K | Rs 1.5-6L |
| 4 Scale | 9-12 | 100-300K | 30-90K | Rs 1.5-6L+ |

Honest read: Year 1 is about proving retention + a repeatable sponsorship motion.
A real, durable business emerges around 100K-500K installs with concentrated
language verticals and direct ad sales — likely Year 2 territory.

---

## Monetization priority order (by leverage at small scale)

1. Sponsorships (highest Rs per engaged user; works even at tiny scale)
2. Content prioritization (paid featured placement; cap to protect trust)
3. Ads (scales with MAU; low eCPM in India)
4. Subscription (Rs 99/yr; keep as "remove ads + premium voices", web/UPI preferred)

---

## Key risks + mitigations

| Risk | Mitigation |
|---|---|
| Low retention | Nail onboarding + daily habit (astrology/story) + great voice quality |
| Rs 9 sub too low to matter | Lead with sponsorships; frame sub as Rs 99/yr value bundle |
| Store cut (15-30%) | Steer subs to web Razorpay/UPI (~98% kept) |
| Bad regional TTS | Hard QA gate; ship language only when voice passes |
| Content legal risk | Stick to CC BY / public domain / commissioned; attribution registry |
| Crowded market | Win a niche (devotion/stories in specific languages) before broadening |

---

## The 5 metrics to watch weekly

1. D30 retention (north star early)
2. Activation rate (install -> first play)
3. Daily content open rate (astrology/story habit)
4. Sponsorship pipeline (Rs committed)
5. Sub conversion + churn (later phases)
