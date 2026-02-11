// onboarding_view.dart
// Steel by Exo — Onboarding Screen
//
// First screen new users see. Introduces Steel's value prop
// and guides them to the main NFC tap experience.
// Matches the hero section of steel.html:
//   "Steel by Exo" badge → "Access Redefined." → "Tap. Verify. Connect"

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/steel_theme.dart';
import '../../providers/providers.dart';
import '../components/ambient_glow.dart';
import '../components/particle_background.dart';
import '../components/platform_shell.dart';
import '../components/steel_button.dart';
import '../components/steel_logo.dart';
import '../home/home_view.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: SteelAnimation.reveal,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), // Slide up from 20px below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start entrance animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      showLogo: false, // We show the logo manually inside the content
      child: Scaffold(
        backgroundColor: SteelColors.background,
        body: Stack(
          children: [
            // Background effects
            const AmbientGlow(),
            const ParticleBackground(),

            // Steel logo — top left
            const Positioned(
              top: 50,
              left: 20,
              child: SteelLogo(width: 90, opacity: 0.8),
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SteelSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // "Steel by Exo" badge — matches the HTML header badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: SteelColors.glassBorder),
                          borderRadius: BorderRadius.circular(SteelRadius.pill),
                        ),
                        child: Text(
                          'STEEL BY EXO',
                          style: SteelFonts.badge.copyWith(
                            color: SteelColors.textMuted,
                            letterSpacing: 3,
                          ),
                        ),
                      ),

                      const SizedBox(height: SteelSpacing.xxl),

                      // "Access Redefined." — hero title
                      // Matches: font-serif text-5xl "Access" + italic "Redefined."
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Access ',
                              style: SteelFonts.heroTitle,
                            ),
                            TextSpan(
                              text: 'Redefined.',
                              style: SteelFonts.heroTitle.copyWith(
                                fontStyle: FontStyle.italic,
                                color: SteelColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: SteelSpacing.lg),

                      // Tagline — "Tap. Verify. Connect — with absolute control."
                      Text(
                        'Tap. Verify. Connect —\nwith absolute control.',
                        textAlign: TextAlign.center,
                        style: SteelFonts.bodyLight.copyWith(
                          fontSize: 18,
                          height: 1.6,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // CTA Button — "Get Started"
                      SteelButton(
                        label: 'Get Started',
                        onPressed: () {
                          ref.read(authServiceProvider).completeOnboarding();
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context2, anim1, anim2) => const HomeView(),
                              transitionsBuilder: (context3, animation, anim2, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: SteelAnimation.standard,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: SteelSpacing.md),

                      // Secondary — "Already a member? Sign in"
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to sign-in screen
                          // For MVP, just skip to home
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomeView()),
                          );
                        },
                        child: Text(
                          'Already a member? Sign in',
                          style: SteelFonts.caption.copyWith(
                            color: SteelColors.textMuted,
                          ),
                        ),
                      ),

                        const SizedBox(height: SteelSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
