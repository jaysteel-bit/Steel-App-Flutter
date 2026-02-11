// glass_card.dart
// Steel by Exo — Glassmorphism Card Widget
//
// Ported from GlassCard.swift (iOS) + .glass CSS class in steel.html.
// Creates the signature frosted glass effect:
//   background: rgba(255, 255, 255, 0.05)
//   border: 1px solid rgba(255, 255, 255, 0.1)
//   backdrop-filter: blur(12px)
//   border-radius: 24px

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/steel_theme.dart';

/// Steel's signature glassmorphism card.
/// Wraps any child widget in a frosted glass container with blur effect.
///
/// Usage:
/// ```dart
/// GlassCard(
///   child: Text('Hello Steel'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurAmount;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = SteelRadius.large,
    this.blurAmount = 12.0,
    this.padding = const EdgeInsets.all(SteelSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // The blur that creates the frosted glass effect
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Semi-transparent white fill — matches .glass CSS
            color: SteelColors.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: SteelColors.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
