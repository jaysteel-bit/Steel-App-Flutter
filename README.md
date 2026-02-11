# Steel by Exo — Flutter

**Privacy-first NFC tap-to-share social ecosystem.**
iOS + Android + Web PWA.

## What is Steel?

Steel is the modern identity layer for high-performers. One tap to share your profile, connect at events, and control exactly who sees what. Think Hermes meets Modern Tech.

### Core Flow (Hybrid — Option 3)

```
Person A (Steel member) taps "Share Profile"
    → Phone enters NFC write mode
    → Person B taps their phone

┌─────────────────────────────────────────────┐
│ Privacy Mode determines what happens next:  │
├─────────────────────────────────────────────┤
│ PUBLIC:  Instant profile reveal (viral)     │
│ PRIVATE: SMS PIN verification first         │
│ EVENT:   PIN once, then free sharing        │
└─────────────────────────────────────────────┘

Person B sees profile card with:
    → Name, photo, headline, social links
    → "Add to Contacts" / "Join the Waitlist" CTAs
```

## Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on Chrome (Web PWA — works immediately)
flutter run -d chrome

# 3. Run on Android (with NFC hardware)
flutter run -d android

# 4. Run on iOS
flutter run -d ios

#5. Run on Web Server
flutter run -d web-server
```

**Simulate Mode** is enabled by default — no NFC hardware needed for development.
Toggle it in Settings > Developer > Simulate Mode.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── theme/
│   └── steel_theme.dart               # Design system (colors, fonts, spacing)
├── models/
│   ├── steel_profile.dart             # Profile model with privacy gradient
│   ├── verification_state.dart        # Verification flow state machine
│   └── steel_connection.dart          # NFC share event logging model
├── services/
│   ├── nfc_service.dart               # NFC read/write (nfc_manager)
│   ├── sms_verification_service.dart  # PIN verification (Twilio stub)
│   ├── profile_service.dart           # Profile fetch + share logging
│   └── auth_service.dart              # Authentication (Supabase stub)
├── providers/
│   └── providers.dart                 # Riverpod providers
├── views/
│   ├── components/
│   │   ├── glass_card.dart            # Glassmorphism card widget
│   │   ├── orb_view.dart              # Animated orb (particles + glow)
│   │   ├── metallic_text.dart         # Shimmer text effect
│   │   ├── steel_button.dart          # Primary/secondary/pill buttons
│   │   ├── ambient_glow.dart          # Background emerald glow
│   │   └── particle_background.dart   # Floating particle effect
│   ├── onboarding/
│   │   └── onboarding_view.dart       # "Access Redefined." intro screen
│   ├── home/
│   │   └── home_view.dart             # Main navigation (Connect + Profile)
│   ├── nfc/
│   │   └── nfc_tap_view.dart          # Core NFC tap screen (orb + states)
│   ├── verification/
│   │   └── verification_view.dart     # PIN entry screen (private mode)
│   └── profile/
│       ├── profile_reveal_view.dart   # Profile card (post-verification)
│       └── profile_settings_view.dart # Settings (privacy mode, dev tools)
```

## Design System

Ported from `steel.html` web prototype:

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#050505` | Main app background |
| `surface` | `#0A0A0A` | Card surfaces |
| `surfaceAlt` | `#1F1F1F` | Inputs, PIN fields |
| `text` | `#F5F5F5` | Primary text |
| `textMuted` | `#A3A3A3` | Secondary text |
| `accent` | `#10B981` | Emerald — primary accent |
| Serif font | Playfair Display | Headlines, names |
| Sans font | Inter | Body, labels, buttons |

## Key Technologies

- **Flutter 3.10+** — Cross-platform (iOS, Android, Web)
- **Riverpod** — State management
- **nfc_manager** — NFC read/write (NDEF)
- **google_fonts** — Inter + Playfair Display
- **shimmer** — Metallic text effect

## NFC NDEF Tag Structure

Written to tags during "Share Profile":

```
Record 1: URI    → https://steel.app/p/{slug}?src=nfc&uid={id}&ts={timestamp}
Record 2: Text   → Member name
Record 3: Custom → com.exo.steel:connect (member ID + privacy mode + version)
```

## Platform Configuration

### Android
- NFC permissions in `AndroidManifest.xml` (already configured)
- NDEF discovery intent filter for `steel.app` URLs
- Deep link handling for `https://steel.app/*`

### iOS
- Add "Near Field Communication Tag Reading" capability in Xcode
- Add `NFCReaderUsageDescription` to `Info.plist`
- Configure Associated Domains: `applinks:steel.app`

### Web
- PWA manifest configured with Steel branding
- NFC not available — auto-enables Simulate Mode
- Dark loading screen while Flutter initializes

## Backend Stubs

Services use stub/mock data for MVP development. Production endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/profiles/{slug}` | GET | Fetch public profile |
| `/api/nfc/share` | POST | Log share event |
| `/api/verification/send-pin` | POST | Send SMS PIN (Twilio) |
| `/api/verification/verify` | POST | Verify PIN |
| `/api/connections/request` | POST | Non-member connect back |

## How to View the UI

1. **Web (fastest):** `flutter run -d chrome` — see the full flow in your browser
2. **Android:** `flutter run -d android` — real NFC on physical device
3. **VS Code:** Open project, press F5, select Chrome/Android

### UI Flow Demo
1. App opens → **Onboarding** ("Access Redefined." + "Get Started" button)
2. Tap "Get Started" → **NFC Tap Screen** (orb animation + "Simulate Tap")
3. Tap "Simulate Tap" → orb intensifies → profile loads
4. **Profile Card** appears with glassmorphism, metallic name, social links, CTAs
5. Go to **Settings** tab to switch privacy mode (Public/Private/Event)

## Relationship to iOS Version

The iOS native version lives at `github.com/jaysteel-bit/Steel-App-iOS.git`.
This Flutter version ports the same architecture but adds:
- Cross-platform (Android + Web in addition to iOS)
- Hybrid privacy flow (Public + Private + Event modes)
- Viral one-tap sharing for growth (Perplexity spec)
- Web PWA fallback for non-members

## License

Proprietary — Steel by Exo (Exo Enterprise).
