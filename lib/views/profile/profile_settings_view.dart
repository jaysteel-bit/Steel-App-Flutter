// profile_settings_view.dart
// Steel by Exo — Profile & Settings Screen
//
// Allows users to:
//   - View/edit their own profile
//   - Set privacy mode (Public / Private / Event)
//   - Toggle simulate mode for development
//   - Sign out

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/steel_theme.dart';
import '../../models/verification_state.dart';
import '../../providers/providers.dart';
import '../components/glass_card.dart';

class ProfileSettingsView extends ConsumerWidget {
  const ProfileSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyMode = ref.watch(privacyModeProvider);
    final simulateMode = ref.watch(simulateModeProvider);

    return Scaffold(
      backgroundColor: SteelColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SteelSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: SteelSpacing.md),

              // Header
              Text('Settings', style: SteelFonts.sectionTitle),

              const SizedBox(height: SteelSpacing.xxl),

              // ── PRIVACY MODE SELECTOR ──
              // From the Perplexity spec: user-controlled privacy levels
              Text(
                'PRIVACY MODE',
                style: SteelFonts.badge.copyWith(
                  color: SteelColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: SteelSpacing.md),

              // Privacy mode cards
              ...PrivacyMode.values.map((mode) {
                final isSelected = privacyMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: SteelSpacing.sm),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(privacyModeProvider.notifier).state = mode;
                    },
                    child: GlassCard(
                      padding: const EdgeInsets.all(SteelSpacing.md),
                      child: Row(
                        children: [
                          // Radio indicator
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? SteelColors.accent
                                    : SteelColors.textMuted,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: SteelColors.accent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: SteelSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode.displayName,
                                  style: SteelFonts.button.copyWith(
                                    color: isSelected
                                        ? SteelColors.accent
                                        : SteelColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mode.description,
                                  style: SteelFonts.captionSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: SteelSpacing.xxl),

              // ── DEVELOPER SETTINGS ──
              Text(
                'DEVELOPER',
                style: SteelFonts.badge.copyWith(
                  color: SteelColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: SteelSpacing.md),

              GlassCard(
                padding: const EdgeInsets.all(SteelSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simulate Mode', style: SteelFonts.button),
                        const SizedBox(height: 4),
                        Text(
                          'Use mock NFC data (no hardware needed)',
                          style: SteelFonts.captionSmall,
                        ),
                      ],
                    ),
                    Switch(
                      value: simulateMode,
                      activeTrackColor: SteelColors.accent,
                      onChanged: (value) {
                        ref.read(simulateModeProvider.notifier).state = value;
                        final nfcService = ref.read(nfcServiceProvider);
                        if (value) {
                          nfcService.enableSimulateMode();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: SteelSpacing.xxl),

              // Version info
              Center(
                child: Text(
                  'Steel by Exo  ·  v1.0.0',
                  style: SteelFonts.captionSmall.copyWith(
                    color: const Color(0xFF525252),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
