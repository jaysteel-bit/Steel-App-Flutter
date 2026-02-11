// steel_logo.dart
// Steel by Exo — Logo Widget
//
// Displays the Steel logo in the top-left corner of screens.
// Matches steel.html: fixed top-8 left-8, w-32, opacity-80 hover:opacity-100

import 'package:flutter/material.dart';

/// Steel logo displayed in the top-left corner.
/// Uses the transparent PNG from assets/images/steel_logo.png.
class SteelLogo extends StatelessWidget {
  final double width;
  final double opacity;

  const SteelLogo({
    super.key,
    this.width = 100,
    this.opacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        'assets/images/steel_logo.png',
        width: width,
        fit: BoxFit.contain,
        // Graceful fallback if image fails to load
        errorBuilder: (context, error, stackTrace) {
          return Text(
            'STEEL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: opacity),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 6,
            ),
          );
        },
      ),
    );
  }
}
