// steel_button.dart
// Steel by Exo — Custom Button Widgets
//
// Ported from SteelButton.swift (iOS) + button styles in steel.html.
// Two main variants:
//   1. Primary: Emerald background, black text (CTA buttons)
//      CSS: bg-brand-accent text-black font-medium rounded-full
//   2. Secondary: White/10 background, white text (secondary actions)
//      CSS: bg-white/10 text-white font-medium rounded-lg

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/steel_theme.dart';

/// Primary CTA button — emerald background, black text.
/// Used for: "Simulate Tap", "Add to Contacts", "Request Invite".
class SteelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const SteelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          // Haptic feedback on tap — matches iOS HapticFeedback
          HapticFeedback.mediumImpact();
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: SteelColors.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SteelRadius.medium),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: SteelFonts.button.copyWith(color: Colors.black)),
                ],
              ),
      ),
    );
  }
}

/// Secondary action button — semi-transparent white background.
/// Used for: "Join the Waitlist", secondary CTAs.
class SteelButtonSecondary extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const SteelButtonSecondary({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SteelRadius.medium),
          ),
          elevation: 0,
        ),
        child: Text(label, style: SteelFonts.button),
      ),
    );
  }
}

/// Pill-shaped button — fully rounded, for special CTAs.
/// Used for: "Simulate Tap" on the NFC screen.
class SteelButtonPill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SteelButtonPill({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : () {
        HapticFeedback.heavyImpact();
        onPressed?.call();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: SteelColors.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SteelRadius.pill),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Text(label, style: SteelFonts.button.copyWith(color: Colors.black)),
    );
  }
}
