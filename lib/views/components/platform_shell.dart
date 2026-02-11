// platform_shell.dart
// Steel by Exo — Platform-Adaptive Layout Shell
//
// MODULAR PLATFORM SYSTEM:
// This widget wraps any screen and adapts its layout for:
//   - WEB:     Centered phone mockup frame (max 420px) on dark background
//              with Steel branding around it. Looks like the steel.html demo.
//   - MOBILE:  Full-screen native layout (no mockup frame).
//
// HOW TO MAKE WEB DIFFERENT FROM MOBILE:
// Each view can check `PlatformShell.isWeb(context)` or use the
// `PlatformAdaptive` widget to show different content per platform:
//
//   PlatformAdaptive(
//     mobile: MobileProfileView(),    // Full-screen native
//     web: WebProfileView(),          // Wider layout, marketing CTAs
//   )
//
// The shell itself handles the "phone frame" wrapper automatically.
// Your views just build their content — the shell decides how to display it.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/steel_theme.dart';
import 'steel_logo.dart';

/// Wraps a screen with platform-appropriate layout.
///
/// On web: Shows the content inside a phone-shaped frame (like the steel.html
/// demo), with the Steel logo and branding visible outside the frame.
///
/// On mobile: Shows the content full-screen with no frame.
///
/// Usage:
/// ```dart
/// PlatformShell(
///   showLogo: true,
///   child: YourScreenContent(),
/// )
/// ```
class PlatformShell extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final bool showPhoneFrame; // On web, wrap content in a phone mockup

  const PlatformShell({
    super.key,
    required this.child,
    this.showLogo = true,
    this.showPhoneFrame = true,
  });

  /// Check if we're running on web. Use this in views to adapt content.
  static bool isWebPlatform() => kIsWeb;

  /// Check screen width to determine if we should show desktop/tablet layout.
  static bool isWideScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    // On mobile (iOS/Android): just show the child full-screen with logo overlay
    if (!kIsWeb) {
      return Stack(
        children: [
          child,
          // Logo in top-left
          if (showLogo)
            const Positioned(
              top: 50, // Below status bar
              left: 16,
              child: SteelLogo(width: 80, opacity: 0.7),
            ),
        ],
      );
    }

    // On web: show phone frame mockup on wide screens, full on narrow
    final isWide = isWideScreen(context);

    if (!isWide || !showPhoneFrame) {
      // Narrow web (mobile browser) — full screen like native
      return Stack(
        children: [
          child,
          if (showLogo)
            const Positioned(
              top: 16,
              left: 16,
              child: SteelLogo(width: 80, opacity: 0.7),
            ),
        ],
      );
    }

    // Wide web — centered phone frame with branding around it
    return Scaffold(
      backgroundColor: SteelColors.background,
      body: Stack(
        children: [
          // Full-page dark background
          Container(color: SteelColors.background),

          // Logo top-left (outside the phone frame)
          if (showLogo)
            const Positioned(
              top: 32,
              left: 32,
              child: SteelLogo(width: 120, opacity: 0.8),
            ),

          // Centered phone mockup frame
          Center(
            child: Container(
              width: 390, // iPhone 14 Pro width
              height: 844, // iPhone 14 Pro height
              margin: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: SteelColors.surface,
                borderRadius: BorderRadius.circular(40), // Phone corner radius
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: SteelColors.accent.withValues(alpha: 0.05),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: child,
              ),
            ),
          ),

          // "View on mobile for best experience" hint at bottom
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Best experienced on mobile  ·  steel.app',
                style: SteelFonts.captionSmall.copyWith(
                  color: const Color(0xFF404040),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show different widgets depending on the platform.
/// Use this inside views when you want web to look different from mobile.
///
/// ```dart
/// PlatformAdaptive(
///   mobile: CompactProfileCard(),
///   web: ExpandedProfileCard(showWaitlistCTA: true),
/// )
/// ```
class PlatformAdaptive extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const PlatformAdaptive({
    super.key,
    required this.mobile,
    required this.web,
  });

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? web : mobile;
  }
}
