// ambient_glow.dart
// Steel by Exo — Ambient Glow Background
//
// Ported from AmbientGlowView.swift (iOS) + ambient glow CSS in steel.html.
// Creates the emerald radial glow orbs in the background:
//   #ambient-glow-1: top-left, 600px, emerald, blur(100px), opacity 0.15
//   #ambient-glow-2: bottom-right, 600px, emerald, blur(100px), opacity 0.15

import 'package:flutter/material.dart';
import '../../theme/steel_theme.dart';

/// Background layer with ambient emerald glow orbs.
/// Place this behind the main content using a Stack.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     const AmbientGlow(),
///     // ... your content
///   ],
/// )
/// ```
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top-left glow — matches #ambient-glow-1
          Positioned(
            top: -200,
            left: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SteelColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Bottom-right glow — matches #ambient-glow-2
          Positioned(
            bottom: -200,
            right: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SteelColors.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
