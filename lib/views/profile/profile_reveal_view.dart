// profile_reveal_view.dart
// Steel by Exo — Profile Reveal Screen
//
// Ported from ProfileRevealView.swift (iOS) + #profile state in steel.html.
// Shown after successful NFC tap (public mode) or PIN verification (private mode).
//
// This is what the receiver sees — the sharer's full profile card:
//   - Glass card container (glassmorphism)
//   - Profile photo with emerald border
//   - Name (metallic shimmer text)
//   - Headline / title
//   - "Steel Member" badge
//   - Social links grid (Instagram, LinkedIn, Contact)
//   - CTA buttons: "Add to Contacts" + "Join the Waitlist"
//
// Matches the HTML #profile section exactly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/steel_theme.dart';
import '../../models/steel_profile.dart';
import '../../providers/providers.dart';
import '../components/glass_card.dart';
import '../components/metallic_text.dart';
import '../components/steel_button.dart';

class ProfileRevealView extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const ProfileRevealView({
    super.key,
    required this.onClose,
  });

  @override
  ConsumerState<ProfileRevealView> createState() => _ProfileRevealViewState();
}

class _ProfileRevealViewState extends ConsumerState<ProfileRevealView>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance animation — matches GSAP: opacity 0→1, y 20→0, stagger children
    _revealController = AnimationController(
      vsync: this,
      duration: SteelAnimation.reveal,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    ));

    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileService = ref.watch(profileServiceProvider);
    final profile = profileService.currentProfile ?? SteelProfile.mock;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SteelSpacing.lg),
            child: Column(
              children: [
                // Close button — top right
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      color: SteelColors.textMuted,
                    ),
                  ),
                ),

                // ── PROFILE CARD ──
                // Matches HTML: .glass.rounded-2xl.p-8 container
                GlassCard(
                  padding: const EdgeInsets.all(SteelSpacing.xl),
                  child: Column(
                    children: [
                      // Profile photo with emerald border
                      // Matches HTML: w-32 h-32 rounded-full border-4 border-brand-accent/50
                      _ProfilePhoto(avatarURL: profile.avatarURL),

                      const SizedBox(height: SteelSpacing.lg),

                      // Name — metallic shimmer text
                      // Matches HTML: font-serif text-4xl italic metallic-text
                      MetallicText(
                        profile.displayName,
                        style: SteelFonts.cardName,
                      ),

                      const SizedBox(height: SteelSpacing.sm),

                      // Headline — "Creative Director | NYC"
                      Text(
                        profile.headline,
                        style: SteelFonts.caption,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: SteelSpacing.md),

                      // Membership badge — "Steel Member"
                      // Matches HTML: px-4 py-1 bg-brand-accent/10 text-brand-accent text-xs
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: SteelColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(SteelRadius.pill),
                        ),
                        child: Text(
                          profile.membershipTier.displayName.toUpperCase(),
                          style: SteelFonts.badge.copyWith(
                            color: SteelColors.accent,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: SteelSpacing.xl),

                      // Social links grid — 3 columns
                      // Matches HTML: grid grid-cols-3 gap-6
                      _SocialLinksGrid(socials: profile.publicSocials),

                      // Bio (if available)
                      if (profile.bio != null) ...[
                        const SizedBox(height: SteelSpacing.lg),
                        Text(
                          profile.bio!,
                          style: SteelFonts.bodyLight.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: SteelSpacing.xl),

                      // CTA Buttons
                      // Matches HTML: "Add to Contacts" (primary) + "Join the Waitlist" (secondary)
                      SteelButton(
                        label: 'Add to Contacts',
                        icon: Icons.person_add,
                        onPressed: () {
                          // TODO: Export vCard / add to native contacts
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Contact saved!',
                                style: SteelFonts.caption.copyWith(color: Colors.black),
                              ),
                              backgroundColor: SteelColors.accent,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: SteelSpacing.md),

                      SteelButtonSecondary(
                        label: 'Join the Waitlist',
                        onPressed: () {
                          // TODO: Navigate to waitlist / app store
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Opening Steel waitlist...',
                                style: SteelFonts.caption.copyWith(color: Colors.black),
                              ),
                              backgroundColor: SteelColors.accent,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SteelSpacing.lg),

                // Steel branding footer
                // Matches HTML: text-xs text-gray-600 footer
                Text(
                  'Shared via Steel  ·  Exclusive Identity Platform',
                  style: SteelFonts.captionSmall.copyWith(
                    color: const Color(0xFF525252),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile photo with emerald accent border.
class _ProfilePhoto extends StatelessWidget {
  final String? avatarURL;

  const _ProfilePhoto({this.avatarURL});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: SteelColors.accent.withValues(alpha: 0.5),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: SteelColors.accent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: avatarURL != null
            ? Image.network(
                avatarURL!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: SteelColors.surfaceAlt,
      child: const Icon(Icons.person, size: 48, color: SteelColors.textMuted),
    );
  }
}

/// Social links displayed in a 3-column grid.
/// Matches HTML: grid grid-cols-3 gap-6 with icon + handle text.
class _SocialLinksGrid extends StatelessWidget {
  final List<SocialLink> socials;

  const _SocialLinksGrid({required this.socials});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SteelSpacing.lg,
      runSpacing: SteelSpacing.md,
      alignment: WrapAlignment.center,
      children: socials.map((social) {
        return GestureDetector(
          onTap: () {
            // TODO: Open social link via url_launcher
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                social.platform.icon,
                size: 32,
                color: SteelColors.text,
              ),
              const SizedBox(height: 8),
              Text(
                social.handle,
                style: SteelFonts.captionSmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
