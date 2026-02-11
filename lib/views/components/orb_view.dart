// orb_view.dart
// Steel by Exo — Animated Orb Widget
//
// Ported from OrbView.swift (iOS) + particles.js orb config in steel.html.
// The orb is the central visual element on the NFC tap screen:
//   - Pulsing, glowing circle with particle-like energy
//   - Emerald green accent (#10b981) with radial gradient
//   - Animates between idle (subtle pulse) and active (intense glow + scan line)
//
// In the HTML prototype, this uses particles.js with 80 white particles
// and linked lines. In Flutter, we use CustomPainter for performance.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/steel_theme.dart';

/// The animated orb displayed on the NFC tap screen.
/// Shows a pulsing, glowing circle that intensifies during scanning.
class OrbView extends StatefulWidget {
  final double size;
  final bool isActive;  // True when scanning/verifying (intensifies animation)
  final bool showScanLine; // True during verification (sweeping green line)

  const OrbView({
    super.key,
    this.size = 192,       // Matches HTML: w-48 h-48 = 192px
    this.isActive = false,
    this.showScanLine = false,
  });

  @override
  State<OrbView> createState() => _OrbViewState();
}

class _OrbViewState extends State<OrbView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();

    // Pulse animation — subtle breathing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Particle rotation — slow continuous spin
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Scan line — sweeps top to bottom during verification
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(OrbView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showScanLine && !oldWidget.showScanLine) {
      _scanLineController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _particleController, _scanLineController]),
      builder: (context, child) {
        // Scale factor: idle = subtle (0.95-1.05), active = stronger (0.9-1.1)
        final pulseScale = widget.isActive
            ? 0.9 + (_pulseController.value * 0.2)
            : 0.95 + (_pulseController.value * 0.1);

        // Glow intensity: idle = dim, active = bright
        final glowOpacity = widget.isActive ? 0.4 : 0.2;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Transform.scale(
                scale: pulseScale * 1.3,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SteelColors.accent.withValues(alpha: glowOpacity * 0.5),
                        SteelColors.accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main orb body
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: widget.size * 0.8,
                  height: widget.size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        SteelColors.accent.withValues(alpha: glowOpacity),
                        SteelColors.accent.withValues(alpha: glowOpacity * 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SteelColors.accent.withValues(alpha: glowOpacity * 0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // Particle dots — rotating around the orb
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _OrbParticlePainter(
                  rotation: _particleController.value * 2 * pi,
                  isActive: widget.isActive,
                ),
              ),

              // Scan line (only during verification)
              if (widget.showScanLine)
                Positioned(
                  top: widget.size * _scanLineController.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: SteelColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: SteelColors.accent.withValues(alpha: 0.8),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for particle dots orbiting around the orb.
/// Simulates the particles.js orb effect from steel.html.
class _OrbParticlePainter extends CustomPainter {
  final double rotation;
  final bool isActive;

  _OrbParticlePainter({required this.rotation, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final random = Random(42); // Fixed seed for consistent particle positions

    final particleCount = isActive ? 60 : 30;
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < particleCount; i++) {
      // Each particle has a fixed angle offset + the current rotation
      final angle = (i / particleCount) * 2 * pi + rotation + (random.nextDouble() * 0.5);
      final distance = radius * (0.3 + random.nextDouble() * 0.6);
      final particleSize = 1.0 + random.nextDouble() * 2.0;
      final opacity = 0.3 + random.nextDouble() * 0.5;

      paint.color = Colors.white.withValues(alpha: opacity);

      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // Draw connecting lines between nearby particles (matches particles.js line_linked)
    if (isActive) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 0.5;

      for (int i = 0; i < min(20, particleCount); i++) {
        final angle1 = (i / particleCount) * 2 * pi + rotation;
        final dist1 = radius * (0.3 + random.nextDouble() * 0.5);
        final p1 = Offset(center.dx + cos(angle1) * dist1, center.dy + sin(angle1) * dist1);

        final j = (i + 1) % particleCount;
        final angle2 = (j / particleCount) * 2 * pi + rotation;
        final dist2 = radius * (0.3 + random.nextDouble() * 0.5);
        final p2 = Offset(center.dx + cos(angle2) * dist2, center.dy + sin(angle2) * dist2);

        canvas.drawLine(p1, p2, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_OrbParticlePainter oldDelegate) =>
      rotation != oldDelegate.rotation || isActive != oldDelegate.isActive;
}
