// particle_background.dart
// Steel by Exo — Background Particle Effect
//
// Ported from ParticleEmitterView.swift (iOS) + particles.js config in steel.html.
// Creates subtle floating emerald particles in the background:
//   particles: { number: 30, color: '#10b981', opacity: 0.3, size: 3, speed: 0.5 }
//
// Uses CustomPainter for performance across all platforms including web.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/steel_theme.dart';

/// Subtle floating particle background effect.
/// Place behind main content in a Stack.
class ParticleBackground extends StatefulWidget {
  final int particleCount;

  const ParticleBackground({
    super.key,
    this.particleCount = 30, // Matches steel.html particles config
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _particles = _generateParticles();
  }

  List<_Particle> _generateParticles() {
    final random = Random();
    return List.generate(widget.particleCount, (_) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 1.0 + random.nextDouble() * 3.0,     // 1-4px (matches size: 3, random: true)
        opacity: 0.1 + random.nextDouble() * 0.3,    // 0.1-0.4 (matches opacity: 0.3, random: true)
        speedX: (random.nextDouble() - 0.5) * 0.0005, // Very slow drift
        speedY: (random.nextDouble() - 0.5) * 0.0005,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particle positions
        for (final p in _particles) {
          p.x = (p.x + p.speedX) % 1.0;
          p.y = (p.y + p.speedY) % 1.0;
          if (p.x < 0) p.x += 1.0;
          if (p.y < 0) p.y += 1.0;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(particles: _particles),
        );
      },
    );
  }
}

class _Particle {
  double x;      // 0-1 normalized position
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = SteelColors.accent.withValues(alpha: p.opacity);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
