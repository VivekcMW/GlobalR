# Design System & Payments Spec — India Interest Radio

**Design system:** Material 3 (Material You), Flutter-native.
**Design style:** "Calm Audio, Indian Warmth" — serene, content-forward, dark-first.
**Payments:** Store IAP in-app (mandatory) + Razorpay/UPI on web (best margin).

---

## 0. Payment reality (READ FIRST — non-negotiable platform rule)

The subscription is a digital good consumed in-app, which triggers store rules:

| Where | Forced payment method | Fee |
|---|---|---|
| iOS app | Apple In-App Purchase (no choice) | 15-30% |
| Android app | Google Play Billing (digital goods) | 15-30% |
| Your website | Razorpay / any gateway (UPI, cards) | ~2% |

- You CANNOT use Razorpay inside the app for the subscription — Apple/Google reject it.
- Razorpay/UPI is for WEB purchases only.
- Smart play: sell subscription on website via Razorpay UPI at full margin (~98% kept)
  AND via store IAP in-app for convenience (~70-85% kept). Steer price-sensitive
  users to web checkout.

---

## 1. Design system: Material 3 (recommendation)

| Why M3 | |
|---|---|
| Native to Flutter | First-class support, no extra weight |
| Dynamic color (Material You) | Adapts to wallpaper, feels personal/premium |
| Accessibility built-in | Large text, contrast — vital for older devotional users |
| Free + battle-tested | No licensing, large component set |
| Lightweight | No heavy third-party UI kit |

Use M3 as the base, lightly themed to feel like the brand (not generic Google).
Alternatives considered: Cupertino (iOS-only feel), fully custom — rejected for
higher effort / less cross-platform consistency.

---

## 2. Design style: "Calm Audio, Indian Warmth"

| Element | Choice | Reason |
|---|---|---|
| Mood | Warm, serene, spiritual-but-modern | Fits devotion/stories without being religious-only |
| Color | Deep indigo/maroon base + saffron/gold accent + warm neutrals | Indian warmth, premium, dark-mode friendly |
| Dark mode | Default dark, light optional | Night listening (bhajans, sleep stories), saves battery/data |
| Typography | Noto Sans family | Covers ALL 22 Indian scripts |
| Shape | Soft rounded corners (16-20dp), generous spacing | Calm, friendly, thumb-reachable |
| Imagery | Subtle gradients + simple interest icons, minimal photos | Lightweight, fast, language-neutral |
| Motion | Gentle, slow (waveform pulse, smooth transitions) | Reinforces calm listening |

### Critical India details
- Noto Sans is NON-NEGOTIABLE: only font family that cleanly renders Devanagari,
  Bengali, Tamil, Telugu, Kannada, Malayalam, Gurmukhi, Odia, Ol Chiki, Perso-Arabic, etc.
- Big tap targets + high contrast (many users are 40+ or low-vision).
- Icon + TEXT labels (don't rely on icons alone across 22 languages).

---

## 3. Design tokens

### Color (dark-first; sample hex — tune in Figma)

| Token | Dark | Light | Use |
|---|---|---|---|
| primary | #E0A93B (saffron/gold) | #8A5A00 | CTA, play button, accents |
| onPrimary | #1A1300 | #FFFFFF | text on primary |
| secondary | #6C4A8C (indigo) | #5A3C78 | secondary accents |
| background | #14110E (warm near-black) | #FBF7F0 | app background |
| surface | #1F1A15 | #FFFFFF | cards, sheets |
| onSurface | #EDE6DA | #1F1A15 | primary text |
| error | #FFB4AB | #BA1A1A | errors |
| success | #7FD18B | #2E7D32 | confirmations |

### Typography (Noto Sans)

| Style | Size / weight | Use |
|---|---|---|
| Display | 32 / Bold | Onboarding headers |
| Headline | 24 / SemiBold | Screen titles |
| Title | 18 / Medium | Card titles, station names |
| Body | 15 / Regular | Descriptions |
| Label | 13 / Medium | Buttons, chips |
| Caption | 11 / Regular | Attribution, metadata |

### Spacing / shape
- Spacing scale: 4, 8, 12, 16, 24, 32 dp.
- Corner radius: cards 16dp, sheets 20dp, buttons 12dp, chips full.
- Min tap target: 48x48 dp.

---

## 4. Component list (MVP)

- Interest chip (selectable, icon + label)
- Language picker (script-correct, searchable)
- Voice preset selector (radio cards with sample-play)
- Station card (title, interest tags, play)
- Mini-player (bottom, persistent) + Full player
- "Today" daily card (astrology/story)
- Premium upsell sheet
- Settings rows (language, voice, low-data, account, privacy)
- Empty/offline/error states

---

## 5. End-to-end workflow A: user journey

```
INSTALL
  -> ONBOARDING (no login yet — reduce drop-off)
       pick language(s) -> interests -> voice preset
  -> INSTANT VALUE: radio starts playing immediately (no signup wall)
  -> HOME: "Your Stations" + "Today" (daily astrology/story)
  -> ENGAGE: play / skip / favorite -> signals stored on-device
  -> SOFT ACCOUNT PROMPT (after value): "Save your favorites"
       Firebase Auth (Phone OTP / Google) — stores profile+prefs only
  -> HABIT LOOP: daily push ("Today's horoscope / new story is ready")
  -> MONETIZE: ads for free users; upsell Premium (voices, no ads, offline)
```

Principle: value BEFORE signup. Radio plays in first ~5 seconds. Ask for account
only when there is something to save.

---

## 6. End-to-end workflow B: subscription & payment

```
USER taps "Go Premium"
  -> SHOW PLAN: Rs 99/year (or Rs 9/mo) — "All voices · No ads · Offline · Family"
  -> CHOOSE CHANNEL:
     In-app (iOS/Android): Apple IAP / Google Play Billing
        one tap, trusted, but 15-30% cut
     Web (best margin): website -> Razorpay checkout
        UPI / cards / netbanking (~2% fee)
        Razorpay Subscriptions API = auto-renew (UPI AutoPay / e-mandate)
  -> PAYMENT SUCCESS -> webhook -> mark user "premium" in Firestore
  -> APP reads entitlement -> unlocks voices/offline/ad-free
  -> RENEWAL: store handles IAP auto-renew; Razorpay handles UPI AutoPay
  -> GRACE/EXPIRY: webhook updates entitlement; app reverts to free
```

Recommended gateway: Razorpay (UPI AutoPay, e-mandate, Subscriptions API, easy KYC).
Alternatives: Cashfree, PhonePe PG.

---

## 7. Entitlement architecture (enforce "premium")

```
Payment (IAP receipt OR Razorpay webhook)
  -> receipt/webhook validation in Cloud Function (server-side, never trust client)
  -> write {isPremium, plan, expiry} to Firestore user doc
  -> app fetches entitlement on launch + caches locally
  -> features gate on entitlement (voices, ad-free, offline)
```

This stays "backendless" in spirit — a tiny Cloud Function for validation, not a
streaming server.

---

## 8. Toolchain (design -> ship)

| Stage | Tool | Why |
|---|---|---|
| Design | Figma + Material 3 Design Kit | Standard; M3 kit free |
| Design tokens | Figma variables -> Flutter ThemeData | Single source of truth |
| Icons | Material Symbols | Consistent, tiny |
| Font | Noto Sans (Google Fonts) | All 22 scripts |
| Prototype | Figma interactive prototype | Test onboarding before coding |
| Build | Flutter + Material 3 theme | One codebase |
| Payments | Razorpay (web) + Store IAP (in-app) | Margin + compliance |
| Auth/data | Firebase Auth + Firestore | Free tier, fast |
| Analytics | Firebase Analytics | Funnel + retention |

---

## 9. Flutter Material 3 theme starter (paste-in)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ColorScheme _darkScheme = const ColorScheme.dark(
  primary: Color(0xFFE0A93B),      // saffron/gold
  onPrimary: Color(0xFF1A1300),
  secondary: Color(0xFF6C4A8C),    // indigo
  surface: Color(0xFF1F1A15),
  onSurface: Color(0xFFEDE6DA),
  error: Color(0xFFFFB4AB),
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: const Color(0xFF14110E),
  );
  return base.copyWith(
    // Noto Sans renders all 22 Indian scripts
    textTheme: GoogleFonts.notoSansTextTheme(base.textTheme),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(0, 48), // accessible tap target
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
    ),
  );
}
```

Note: for languages needing specific scripts not in base Noto Sans (e.g. Ol Chiki
for Santali), load the matching Noto font (e.g. Noto Sans Ol Chiki) per locale.

---

## 10. Design/payment definition of done

- [ ] M3 theme applied; brand colors (saffron/indigo, dark-first) in tokens
- [ ] Noto Sans (+ script-specific Noto fonts) render all launched languages correctly
- [ ] Onboarding works with NO login; radio plays within ~5s
- [ ] Tap targets >= 48dp; contrast meets accessibility
- [ ] In-app subscription uses Apple IAP / Google Play Billing
- [ ] Web subscription uses Razorpay (UPI AutoPay / e-mandate)
- [ ] Entitlement validated server-side (Cloud Function) + cached on device
- [ ] Free reverts correctly on expiry/grace
