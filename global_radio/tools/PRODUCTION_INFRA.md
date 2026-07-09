# Production-grade content infrastructure — migration plan

**Status as of 2026-07-10:** everything described here is a plan, not yet
built. The app runs today on an interim architecture (below) that works but
was explicitly chosen for zero cost and no new infra, not for scale. This
document exists so that when the userbase grows enough to need real
infrastructure — instant/live scraping, guaranteed uptime, moderation at
volume — there's a concrete checklist instead of a from-scratch redesign.

Read `CHANGELOG.md`'s 2026-07-09/10 entries first for the *why* behind each
interim choice before assuming it's a mistake to fix — most were deliberate
tradeoffs (free tier, no billing account, one engineer) documented at the
time.

---

## 1. Current (interim) architecture — what exists today

```
User adds custom interest (app, no sign-in required)
    │
    ▼
Firestore `scrapeQueue` collection (globalir project, Spark/free plan)
    │
    ▼  (polled, not pushed — see §2 for why this matters)
GitHub Actions cron (nightly-content.yml)
  ├─ hourly:  drain scrapeQueue only
  └─ 2x/day:  drain scrapeQueue + news/astrology/weather + weekly harvest
    │
    ├─ tools/ingest_public_sources.py   — scrape Wikisource/Wikipedia (English)
    ├─ tools/translate_fanout.py        — deep-translator fan-out to 10 langs
    ├─ tools/auto_promote_drafts.py     — merge into scraped.json, no review
    ├─ tools/build_catalog.py           — render audio (edge-tts, free), write catalog.json
    ├─ tools/fetch_commons_images.py    — real photo via Wikipedia pageimages API
    ├─ tools/build_story_images.py      — AI illustration fallback (Pollinations.ai, free)
    │
    ▼
git push → github.com/prince11jose/globalradio-cdn-content (a plain repo, not a CDN)
    │
    ▼
App fetches https://raw.githubusercontent.com/.../catalog.json + audio/images
```

**Why it's shaped this way:** `globalir` (the Firebase project in active use
— see CHANGELOG 2026-07-09 for why it's `globalir` and not `globalradio-1f547`)
has no billing account, which rules out Cloud Functions, Cloud Storage
buckets, and Cloud Scheduler entirely — none of those have a free tier.
GitHub Actions cron + a plain git repo served via `raw.githubusercontent.com`
is genuinely free and was the only path available without asking for a
credit card. It is **not** a CDN in any real sense: no cache invalidation
control, no edge network, rate-limited by GitHub's abuse-detection on raw
file serving, and a 12-hour-to-1-week content latency depending on demand
signal (see §2).

**Known limits of the interim setup** (each is a concrete trigger for
migrating the corresponding piece below, not a reason to migrate everything
at once):
- No content moderation — everything auto-promotes with zero human review
  (explicit product decision, see CHANGELOG Security section 2026-07-09).
  Fine at hundreds of items; a real risk at thousands with real user-facing
  volume, especially for a Kids Mode app.
- Polling latency (§2) — worst case ~1h for a queued interest, not seconds.
- Pollinations.ai's free tier (1 request/15s, no SLA, can and does 500
  transiently) is not viable at any real content-generation volume.
- `edge-tts` is an unofficial, reverse-engineered wrapper around Microsoft
  Edge's read-aloud feature. It has no published rate limit or SLA and
  could stop working if Microsoft changes anything — there is no support
  contract behind it.
- GitHub raw file serving is explicitly *not* meant to be a CDN and can
  start 429-ing under real traffic; there's no guarantee it stays free or
  available at scale.
- The whole content pipeline runs as one long GitHub Actions job with no
  partial-failure isolation — one interest's scrape hanging blocks
  everything queued behind it in that run.

---

## 2. Real-time scraping — what it actually needs

Today: Firestore write → GitHub Actions polls hourly → picks it up.
Worst-case latency ~1 hour, because there is no push mechanism from
Firestore to anything — this document's predecessor conversation
originally asked for "real-time" and settled on hourly polling specifically
because the two ways to get lower latency both had real costs:

### Option A: Cloud Functions (2nd gen) with a Firestore trigger
```
Firestore write to scrapeQueue
    │  (event, not poll — near-instant)
    ▼
Cloud Function (onDocumentCreated trigger)
    │
    ▼
Cloud Tasks queue → Cloud Run job (does the actual scrape/translate/promote)
    │
    ▼
Cloud Storage (not GitHub raw) → Cloud CDN or Cloudflare in front of it
```
- **Requires Blaze (pay-as-you-go) billing** on the Firebase project —
  Cloud Functions has no free tier deploy path, full stop. This is the
  single blocker that's been hit repeatedly in this project's history
  (see CHANGELOG entries about Cloud Storage/Cloud Functions needing
  billing). Budget: Cloud Functions invocations are cheap (~$0.40/million),
  Cloud Run scrape jobs would run maybe minutes/day at current volume — this
  is a "tens of dollars a month" tier, not a scary one, once billing exists
  at all.
- Gets you actual real-time (seconds), proper retry/dead-letter handling
  (Cloud Tasks), and structured logging/alerting (Cloud Logging + Error
  Reporting) for free once Blaze is on.

### Option B: keep GitHub Actions, drop latency via `workflow_dispatch`
A lighter-weight middle ground if Blaze still isn't approved: a small
**Cloud Function *is* still required** to react to the Firestore write and
call GitHub's `workflow_dispatch` API — Firestore has no way to call an
external webhook without *something* observing it, whether that's a Cloud
Function, a polling loop, or (ruled out below) client-side code. This still
needs Blaze, just a cheaper slice of it (one trigger function, not a full
scrape pipeline) — Cloud Functions' free-tier-equivalent invocation volume
here would be pennies/month once billing exists.

### Ruled out, don't revisit without a strong reason
**Embedding a GitHub PAT or Firebase Admin credential in the client app** so
it can trigger the pipeline directly. A mobile APK is not a trusted
execution environment — anyone can extract embedded strings from it
(`strings`, `apktool`, or just a rooted device + Frida). A credential with
write access to a GitHub repo or Firebase project, shipped to every
installed copy of the app, is a standing invitation to have that repo or
project compromised. This was already raised and rejected once in this
project (CHANGELOG 2026-07-10) — don't re-litigate it without new
information that changes the trust model.

**Recommendation when the time comes:** Option A. It's not meaningfully
more expensive than Option B once Blaze is on at all, and it gets you a
real pipeline (retries, dead-letter, structured logs) instead of a
thin GitHub Actions trigger wrapper.

---

## 3. CDN & storage

Move off `raw.githubusercontent.com` before it becomes a bottleneck, not
after. Two straightforward paths, both already partially stubbed in this
repo:

### Option A: Firebase Storage + Firebase Hosting / Cloud CDN
- `tools/setup_gcp_backend.sh` and `tools/FUTURE_FIREBASE_SETUP.md` already
  document the steps for this (bucket creation, `deploy_content.sh`) — it
  was blocked purely on billing, same as everything else in this doc.
- Natural fit if the rest of the migration goes to Cloud Functions/Cloud
  Run too (§2 Option A) — same project, same billing account, one bill.

### Option B: Cloudflare R2 + Cloudflare CDN
- `tools/deploy_r2.sh` already exists and is wired into `nightly-content.yml`
  (the `Deploy to R2` step) — it just needs `R2_ACCESS_KEY_ID` /
  `R2_SECRET_ACCESS_KEY` / `R2_ACCOUNT_ID` as repo secrets to start working;
  no code changes needed.
- R2 has a genuinely useful free tier (10GB storage, no egress fees ever —
  unlike S3/GCS) and doesn't require Blaze billing on the Firebase side at
  all, making it the **cheapest real upgrade available today**, independent
  of whether/when Cloud Functions billing gets approved.
- **Recommendation: do this one first, regardless of what happens with
  §2.** It's a pure win (real CDN, no new billing dependency, code already
  written) with no reason to wait.

Either way: keep `CDN_BASE`/`CATALOG_URL` as build-time `--dart-define`
overrides (already the pattern in `android-release.yml`/`ios-build.yml`) so
migrating the backend is a CI config change, not an app release.

---

## 4. Content moderation at scale

The current "no review, auto-promote everything" policy was an explicit,
documented tradeoff for an early-stage app with low volume (CHANGELOG
2026-07-09 Security section). Revisit this specifically when any of the
following becomes true, not just "when it feels like a lot":
- Scraped-content volume exceeds what one person could plausibly spot-check
  in `content/library/scraped.json` in a sitting (a rough guide, not a hard
  number — depends on how often anyone actually looks).
- Any user-facing report of inappropriate/wrong/offensive scraped content
  (the day-one signal that the current policy has a real cost, not just a
  theoretical one).
- Kids Mode usage grows to where scraped content (currently tagged by
  interest, not vetted for kid-appropriateness) risks surfacing there.

**What to add, roughly in order of effort:**
1. **Automated content-safety check** before auto-promote: run scraped text
   through a moderation API (OpenAI's moderation endpoint, Perspective API,
   or Google Cloud's Natural Language API content classification) and hold
   anything flagged for human review instead of auto-promoting it. Cheap,
   fast to add, doesn't require redesigning the pipeline.
2. **Kids Mode allowlist, not blocklist**: instead of trying to filter out
   bad scraped content from Kids Mode, only show hand-curated + explicitly
   reviewed content there, ever. Scraped content stays adult/general-mode
   only unless specifically reviewed and promoted into a kids category.
3. **A real review queue** (a simple internal tool, or even a Firestore
   collection + a basic admin screen) once volume justifies it — not
   before. Building this too early is wasted engineering effort against a
   problem that doesn't exist yet.

---

## 5. Scaling the pipeline itself

- **edge-tts**: no published SLA. At real volume, budget for **Azure
  Cognitive Services Speech** (already partially wired — `pipeline.py`'s
  `AZURE_SPEECH_KEY` fallback exists for languages with no free edge voice)
  as the primary TTS backend, not just the odia/punjabi/assamese fallback.
  Azure Speech pricing is per-character; at expected volumes this is a real
  but modest cost, not prohibitive.
- **Pollinations.ai** (free image generation): has no SLA and a hard
  1-request/15s rate limit that's already the bottleneck for the current
  ~150-story catalog. At scale, replace with a paid image API (OpenAI
  Images, Stability AI, or Google Imagen via Vertex AI — the last one
  again needs Blaze billing, same as everything in §2) or a self-hosted
  Stable Diffusion instance if volume is high enough to justify dedicated
  GPU infra.
- **Wikisource/Wikipedia/Commons APIs**: politely rate-limited in the
  current scripts (1 req/sec) and have no official bulk-access SLA either.
  Fine at current scrape volume; if content-sourcing volume grows by an
  order of magnitude, look at Wikimedia's bulk data dumps
  (dumps.wikimedia.org) instead of the live search API for the same
  content, which sidesteps rate limits entirely.
- **Split the monolithic CI job**: `nightly-content.yml` currently runs
  news/astrology/weather/harvest/queue-drain/catalog-build/image-gen/deploy
  as one long sequential job. At scale, split into independent workflows
  triggered by whichever Cloud Tasks/Pub-Sub queue (§2) fans work out to,
  so one slow/stuck scrape doesn't block daily content refresh, and vice
  versa.

---

## 6. Observability

Nothing today alerts anyone when the pipeline silently degrades — every
step in `nightly-content.yml` is wrapped in `|| echo "degraded — continuing"`
specifically so a partial failure doesn't block the rest of the run, but
that also means a fully broken step (e.g. Wikisource changing their API)
could go unnoticed indefinitely. Add before it matters:
- A final step that checks whether anything actually logged "degraded" this
  run and posts to Slack/email/a GitHub issue if so — cheap, no new infra.
- Once on Cloud Functions/Cloud Run (§2 Option A): Cloud Monitoring alerting
  policies on function error rate and Cloud Tasks dead-letter queue depth —
  this comes largely for free with that migration, not a separate project.

---

## 7. Rough migration order

Not everything here needs doing at once, and not necessarily in this exact
order — but this is the dependency-aware sequence if starting from
scratch:

1. **R2 CDN migration (§3 Option B)** — zero new billing dependency, code
   already exists, pure upside. Do this whenever there's an hour free,
   independent of everything else below.
2. **Get Blaze billing approved** on whichever Firebase project is
   production at that time — the actual hard blocker behind §2, §3 Option
   A, and the Vertex AI path in §5. Everything past this point assumes
   it's done.
3. **Content moderation gate (§4.1)** — do this *before* scaling scrape
   volume further, not after; it's much easier to add a check to a small
   pipeline than to retroactively audit a large backlog.
4. **Cloud Functions real-time trigger (§2 Option A)** — once billing
   exists, this is a well-scoped, independent piece of work.
5. **TTS/image-gen paid backends (§5)** — driven by actual rate-limit pain,
   not a fixed date; do this when Pollinations/edge-tts actually start
   failing at your real volume, not preemptively.
6. **Split the CI job / move to Cloud Tasks (§5 last bullet)** — the
   highest-effort, lowest-urgency item; only worth it once the pipeline is
   genuinely too slow or too coupled to iterate on safely.
