// steel_theme.dart
// Steel by Exo — Design System (Flutter)
//
// Single source of truth for Steel's visual identity.
// Ported directly from:
//   - steel.html web prototype (Tailwind config + CSS)
//   - SteelTheme.swift (iOS version)
//
// Design Language:
//   - Dark mode first (#050505 background)
//   - Emerald accent (#10b981)
//   - Glassmorphism (frosted glass cards via BackdropFilter)
//   - Metallic text shimmers
//   - Particle effects and ambient glow
//   - Premium, cyber-luxury aesthetic

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Steel's design system namespace.
/// Usage: SteelColors.background, SteelFonts.headline, SteelSpacing.md, etc.
class SteelColors {
  SteelColors._(); // Prevent instantiation

  // ── Core Palette ──────────────────────────────────────────────
  // Mapped from steel.html tailwind config and SteelTheme.swift:
  //   brand-black:  #050505
  //   brand-dark:   #0a0a0a
  //   brand-gray:   #1f1f1f
  //   brand-text:   #f5f5f5
  //   brand-muted:  #a3a3a3
  //   brand-accent: #10b981 (Emerald)

  static const Color background  = Color(0xFF050505); // Main app background
  static const Color surface     = Color(0xFF0A0A0A); // Card/surface background
  static const Color surfaceAlt  = Color(0xFF1F1F1F); // Elevated surface (PIN fields, inputs)
  static const Color text        = Color(0xFFF5F5F5); // Primary text
  static const Color textMuted   = Color(0xFFA3A3A3); // Secondary/muted text
  static const Color accent      = Color(0xFF10B981); // Emerald green — primary accent
  static const Color accentLight = Color(0xFF34D399); // Lighter emerald for hover/active

  // ── Glass Effect ──────────────────────────────────────────────
  // From .glass CSS class in steel.html:
  //   background: rgba(255, 255, 255, 0.05)
  //   border: 1px solid rgba(255, 255, 255, 0.1)
  //   backdrop-filter: blur(12px)
  static Color glassFill   = Colors.white.withValues(alpha: 0.05);
  static Color glassBorder = Colors.white.withValues(alpha: 0.10);
  static Color glassHover  = Colors.white.withValues(alpha: 0.10);

  // ── Ambient Glow ──────────────────────────────────────────────
  // Radial emerald glow used in background
  static Color glowEmerald = const Color(0xFF10B981).withValues(alpha: 0.15);
}

/// Steel's typography system.
/// Uses Google Fonts: Inter (sans) + Playfair Display (serif).
/// Matches the HTML prototype's font stack exactly.
class SteelFonts {
  SteelFonts._();

  // ── Base Font Builders ────────────────────────────────────────

  /// Serif font — Playfair Display.
  /// Used for: headlines, names, "Tap to Connect", hero text.
  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    Color color = SteelColors.text,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      color: color,
    );
  }

  /// Sans font — Inter.
  /// Used for: body text, labels, buttons, captions.
  static TextStyle sans({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = SteelColors.text,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // ── Pre-built Text Styles ─────────────────────────────────────
  // Matches the HTML prototype sizes and the iOS SteelTheme.swift

  /// "Access Redefined." — h1 hero title (font-serif text-5xl)
  static TextStyle get heroTitle => serif(
    size: 48,
    weight: FontWeight.w500,
  );

  /// Profile name on the card — italic serif (font-serif text-4xl italic)
  static TextStyle get cardName => serif(
    size: 36,
    style: FontStyle.italic,
  );

  /// Section headers
  static TextStyle get sectionTitle => serif(
    size: 28,
    weight: FontWeight.w600,
  );

  /// Subheadings — medium weight sans
  static TextStyle get headline => sans(
    size: 20,
    weight: FontWeight.w500,
  );

  /// Body text
  static TextStyle get body => sans(size: 16);

  /// Light body — descriptions, taglines
  static TextStyle get bodyLight => sans(
    size: 16,
    weight: FontWeight.w300,
    color: SteelColors.textMuted,
  );

  /// Captions
  static TextStyle get caption => sans(
    size: 14,
    color: SteelColors.textMuted,
  );

  /// Small muted text
  static TextStyle get captionSmall => sans(
    size: 12,
    color: SteelColors.textMuted,
  );

  /// Badge/tag text — all-caps, small
  static TextStyle get badge => sans(
    size: 10,
    weight: FontWeight.w500,
  );

  /// Button labels
  static TextStyle get button => sans(
    size: 14,
    weight: FontWeight.w500,
  );
}

/// Consistent spacing scale used throughout the app.
class SteelSpacing {
  SteelSpacing._();

  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

/// Corner radius tokens.
class SteelRadius {
  SteelRadius._();

  static const double small  = 8;   // Small elements (badges, inputs)
  static const double medium = 12;  // Cards, buttons
  static const double large  = 24;  // Phone screen container (rounded-3xl)
  static const double pill   = 9999; // Fully rounded (pills, tags)
}

/// Animation durations and curves matching GSAP timeline from steel.html.
class SteelAnimation {
  SteelAnimation._();

  static const Duration quick    = Duration(milliseconds: 300);
  static const Duration standard = Duration(milliseconds: 600);
  static const Duration slow     = Duration(milliseconds: 800);
  static const Duration reveal   = Duration(milliseconds: 1200);

  static const Curve defaultCurve = Curves.easeOut;
  static const Curve revealCurve  = Curves.easeInOut;
}

/// Builds the full MaterialApp ThemeData for Steel.
/// Apply this to MaterialApp(theme: steelThemeData()).
ThemeData steelThemeData() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SteelColors.background,
    primaryColor: SteelColors.accent,
    colorScheme: const ColorScheme.dark(
      primary: SteelColors.accent,
      secondary: SteelColors.accentLight,
      surface: SteelColors.surface,
      onPrimary: Colors.black,
      onSurface: SteelColors.text,
    ),
    textTheme: TextTheme(
      displayLarge: SteelFonts.heroTitle,
      headlineMedium: SteelFonts.sectionTitle,
      titleLarge: SteelFonts.headline,
      bodyLarge: SteelFonts.body,
      bodyMedium: SteelFonts.bodyLight,
      labelLarge: SteelFonts.button,
      bodySmall: SteelFonts.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SteelColors.accent,
        foregroundColor: Colors.black,
        textStyle: SteelFonts.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SteelRadius.medium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SteelColors.glassFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SteelRadius.small),
        borderSide: BorderSide(color: SteelColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SteelRadius.small),
        borderSide: BorderSide(color: SteelColors.glassBorder),
      ),
      hintStyle: SteelFonts.sans(size: 14, color: const Color(0xFF525252)),
    ),
  );
}
