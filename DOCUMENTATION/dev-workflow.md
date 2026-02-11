# Steel — Development Workflow Guide

> How to run, test, and develop Steel across Web, iOS, and Android.

For full project details see the main [README](../README.md).

---

## Running the App

### Web (Browser Preview)

Best for quick UI iteration. Shows the phone-mockup frame on wide screens.

```bash
# Chrome (recommended — full DevTools)
flutter run -d chrome

# Web server (if Chrome device not available)
flutter run -d web-server
# Then open the printed URL (e.g. http://localhost:62170) in any browser
```

**Note:** NFC is not available on web. The app automatically enables **Simulate Mode** so you can still test the full NFC tap flow with mock data.

### Android

```bash
# List available devices
flutter devices

# Run on connected Android device or emulator
flutter run -d <device-id>

# Example: Run on emulator
flutter run -d emulator-5554
```

To set up an Android emulator:
```bash
# Via Android Studio → Device Manager → Create Virtual Device
# Choose a device with NFC support (Pixel 6+)
```

### iOS (macOS only)

```bash
# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Run on physical device (requires signing)
flutter run -d <device-id>
```

---

## Platform-Adaptive Views

Steel uses a **modular platform system** so web and mobile can look different while sharing core logic.

### How It Works

Every screen is wrapped in `PlatformShell`:

```dart
// Your view just builds its content
PlatformShell(
  showLogo: true,
  child: YourScreenContent(),
)
```

**PlatformShell** automatically handles:
- **Web (wide screen):** Centers content in a 390x844 phone mockup frame with Steel branding outside
- **Web (narrow/mobile browser):** Full-screen, just like native
- **iOS/Android:** Full-screen native layout

### Making Views Different per Platform

Use `PlatformAdaptive` when you want web to look different from mobile:

```dart
PlatformAdaptive(
  mobile: CompactProfileCard(),      // Native: tight, gesture-driven
  web: ExpandedProfileCard(          // Web: wider, marketing CTAs
    showWaitlistCTA: true,
  ),
)
```

### Checking Platform in Code

```dart
// Am I on web?
if (PlatformShell.isWebPlatform()) {
  // Web-specific logic
}

// Is the screen wide enough for desktop layout?
if (PlatformShell.isWideScreen(context)) {
  // Show expanded layout
}
```

### Viewing Both Web and Phone

To develop both views simultaneously:

1. **Phone view:** Run on Android emulator or iOS simulator
   ```bash
   flutter run -d emulator-5554
   ```

2. **Web view:** In a separate terminal, run on Chrome
   ```bash
   flutter run -d chrome
   ```

Both can run at the same time. Hot reload works independently for each.

---

## Project Structure

```
lib/
  theme/            → Design tokens (colors, fonts, spacing)
  models/           → Data models (profile, verification, connection)
  services/         → Business logic (NFC, SMS, profile, auth)
  providers/        → Riverpod state management
  views/
    components/     → Reusable widgets (glass_card, orb, buttons, etc.)
    onboarding/     → First-run experience
    home/           → Main app shell with bottom nav
    nfc/            → NFC tap screen (core experience)
    verification/   → PIN entry screen
    profile/        → Profile reveal + settings

backend/
  convex/           → Convex database schema + functions
```

---

## Simulate Mode

Since NFC hardware isn't available on web or most emulators, Steel has a **Simulate Mode** that returns mock NFC data.

- **Auto-enabled** on web
- **Toggle manually** in Profile → Settings on mobile
- Uses `SteelProfile.mock` data (Alexa Rivera, Founding Member)

---

## Hot Reload vs Hot Restart

- **`r`** — Hot reload: Applies UI changes instantly (use for most edits)
- **`R`** — Hot restart: Full restart (needed after changing state management or adding assets)
