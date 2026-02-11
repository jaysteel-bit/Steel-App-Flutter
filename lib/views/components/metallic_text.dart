// metallic_text.dart
// Steel by Exo — Metallic Shimmer Text Widget
//
// Ported from MetallicText.swift (iOS) + .metallic-text CSS in steel.html.
// Creates the signature metallic text effect:
//   background: linear-gradient(to right, #ffffff 20%, #a0a0a0 50%, #ffffff 80%)
//   background-size: 200% auto
//   animation: shine 5s linear infinite
//
// Uses the shimmer package for the animated gradient sweep.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/steel_theme.dart';

/// Text with an animated metallic shimmer effect.
/// Used for profile names and premium labels.
///
/// Usage:
/// ```dart
/// MetallicText(
///   'Alexa Rivera',
///   style: SteelFonts.cardName,
/// )
/// ```
class MetallicText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const MetallicText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? SteelFonts.cardName;

    return Shimmer.fromColors(
      // Matches the CSS gradient: white → gray → white
      baseColor: Colors.white,
      highlightColor: const Color(0xFFA0A0A0),
      period: const Duration(seconds: 5), // Matches CSS: animation: shine 5s
      child: Text(
        text,
        style: textStyle,
        textAlign: textAlign,
      ),
    );
  }
}
