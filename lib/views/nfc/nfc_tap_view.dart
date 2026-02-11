// nfc_tap_view.dart
// Steel by Exo — NFC Tap Screen (Flutter)
//
// Ported from NFCTapView.swift (iOS) + the interactive phone demo in steel.html.
// This is the CORE experience — the screen users see most:
//
//   STATE 1 (idle):     Orb + "Tap to Connect" + "Simulate Tap" button
//   STATE 2 (scanning): Active orb + "Reading..." indicator
//   STATE 3 (verify):   PIN entry fields + scan line (private mode only)
//   STATE 4 (reveal):   Profile card slides in (glass card with data)
//
// HYBRID FLOW (from Perplexity spec, Option 3):
//   Public Mode:  Skip PIN → go straight to profile reveal
//   Private Mode: Show PIN entry → verify → then reveal
//   Event Mode:   PIN on first tap, then public for rest of session

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/steel_theme.dart';
import '../../models/verification_state.dart';
import '../../providers/providers.dart';
import '../components/ambient_glow.dart';
import '../components/particle_background.dart';
import '../components/orb_view.dart';
import '../components/steel_button.dart';
import '../verification/verification_view.dart';
import '../profile/profile_reveal_view.dart';

class NFCTapView extends ConsumerStatefulWidget {
  const NFCTapView({super.key});

  @override
  ConsumerState<NFCTapView> createState() => _NFCTapViewState();
}

class _NFCTapViewState extends ConsumerState<NFCTapView>
    with TickerProviderStateMixin {

  // Animation controllers for state transitions (matching GSAP timeline in steel.html)
  late AnimationController _stateTransitionController;

  @override
  void initState() {
    super.initState();
    _stateTransitionController = AnimationController(
      vsync: this,
      duration: SteelAnimation.standard,
    );

    // Auto-enable simulate mode on startup
    // In production, this checks actual NFC availability
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final nfcService = ref.read(nfcServiceProvider);
      final hasNFC = await nfcService.isNFCAvailable();
      if (!hasNFC) {
        nfcService.enableSimulateMode();
      }
    });
  }

  @override
  void dispose() {
    _stateTransitionController.dispose();
    super.dispose();
  }

  /// Handle the "Simulate Tap" or actual NFC tap.
  /// This kicks off the entire verification flow.
  Future<void> _handleTap() async {
    final nfcService = ref.read(nfcServiceProvider);
    final verificationState = ref.read(verificationStateProvider.notifier);
    final privacyMode = ref.read(privacyModeProvider);

    // Haptic feedback — the "premium tap" feel
    HapticFeedback.heavyImpact();

    // Transition to scanning state
    verificationState.state = VerificationFlowState.scanning;

    // Start NFC scan (or simulate)
    final sharerId = await nfcService.beginScanning();

    if (sharerId == null) {
      verificationState.state = VerificationFlowState.error;
      return;
    }

    // Tag detected — haptic confirmation
    HapticFeedback.mediumImpact();
    verificationState.state = VerificationFlowState.tagDetected;

    // ── HYBRID FLOW BRANCHING ──
    // Based on the privacy mode selected by the sharer:
    switch (privacyMode) {
      case PrivacyMode.public_:
        // PUBLIC: Skip PIN → go straight to profile
        // This is the viral one-tap flow from the Perplexity spec
        await _loadAndRevealProfile(sharerId);
        break;

      case PrivacyMode.private_:
        // PRIVATE: Require SMS PIN verification
        // This is the privacy-first flow from the iOS version
        await _startPINVerification(sharerId);
        break;

      case PrivacyMode.event:
        // EVENT: PIN on first tap, then public for rest of session
        // TODO: Implement event session tracking
        // For now, behave like public mode
        await _loadAndRevealProfile(sharerId);
        break;
    }
  }

  /// Public mode: Load profile and reveal immediately (one-tap viral flow).
  Future<void> _loadAndRevealProfile(String sharerId) async {
    final profileService = ref.read(profileServiceProvider);
    final verificationState = ref.read(verificationStateProvider.notifier);

    // Log the share event for analytics
    await profileService.logShareEvent(sharerId: sharerId);

    // Fetch the sharer's profile
    final profile = await profileService.fetchProfile(sharerId);

    if (profile != null) {
      HapticFeedback.heavyImpact();
      verificationState.state = VerificationFlowState.profileRevealed;
    } else {
      verificationState.state = VerificationFlowState.error;
    }
  }

  /// Private mode: Send PIN and show verification UI.
  Future<void> _startPINVerification(String sharerId) async {
    final smsService = ref.read(smsVerificationServiceProvider);
    final verificationState = ref.read(verificationStateProvider.notifier);

    // Send SMS PIN to the sharer
    final sent = await smsService.sendPIN(sharerId);

    if (sent) {
      verificationState.state = VerificationFlowState.pinEntry;
    } else {
      verificationState.state = VerificationFlowState.error;
    }
  }

  /// Reset back to idle state.
  void _resetToIdle() {
    ref.read(verificationStateProvider.notifier).state = VerificationFlowState.idle;
    ref.read(profileServiceProvider).clearProfile();
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(verificationStateProvider);
    final nfcService = ref.watch(nfcServiceProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return Scaffold(
      backgroundColor: SteelColors.background,
      body: Stack(
        children: [
          // Background effects
          const AmbientGlow(),
          const ParticleBackground(),

          // Main content — switches based on verification state
          SafeArea(
            child: AnimatedSwitcher(
              duration: SteelAnimation.standard,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildStateContent(flowState, nfcService, privacyMode),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the content for the current verification state.
  /// Each state maps to a visual state from the HTML prototype.
  Widget _buildStateContent(
    VerificationFlowState flowState,
    dynamic nfcService,
    PrivacyMode privacyMode,
  ) {
    switch (flowState) {
      // ── IDLE STATE ────────────────────────────────────────────
      // Matches HTML #locked: Orb + "Tap to Connect" + button
      case VerificationFlowState.idle:
        return _IdleView(
          key: const ValueKey('idle'),
          onTap: _handleTap,
          isSimulateMode: nfcService.isSimulateMode,
          privacyMode: privacyMode,
        );

      // ── SCANNING STATE ────────────────────────────────────────
      // Active orb with intensified animation
      case VerificationFlowState.scanning:
      case VerificationFlowState.tagDetected:
        return _ScanningView(
          key: const ValueKey('scanning'),
          isTagDetected: flowState == VerificationFlowState.tagDetected,
        );

      // ── PIN ENTRY STATE ───────────────────────────────────────
      // Matches HTML #verification: PIN fields + scan line
      case VerificationFlowState.pinEntry:
      case VerificationFlowState.verifying:
        return VerificationView(
          key: const ValueKey('verification'),
          sharerId: nfcService.lastReadSharerID ?? '',
          onVerified: () async {
            final sharerId = nfcService.lastReadSharerID ?? '';
            await _loadAndRevealProfile(sharerId);
          },
          onCancel: _resetToIdle,
        );

      // ── VERIFIED / PROFILE REVEALED ───────────────────────────
      // Matches HTML #profile: Glass card with full profile data
      case VerificationFlowState.verified:
      case VerificationFlowState.profileRevealed:
        return ProfileRevealView(
          key: const ValueKey('profile'),
          onClose: _resetToIdle,
        );

      // ── ERROR STATE ───────────────────────────────────────────
      case VerificationFlowState.error:
        return _ErrorView(
          key: const ValueKey('error'),
          error: nfcService.lastError ?? 'Something went wrong.',
          onRetry: _resetToIdle,
        );
    }
  }
}

// ── IDLE VIEW ─────────────────────────────────────────────────────
// The default "waiting for tap" screen with the orb and simulate button.
class _IdleView extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSimulateMode;
  final PrivacyMode privacyMode;

  const _IdleView({
    super.key,
    required this.onTap,
    required this.isSimulateMode,
    required this.privacyMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SteelSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The orb — idle state (subtle pulse)
            const OrbView(size: 192, isActive: false),

            const SizedBox(height: SteelSpacing.xxl),

            // "Tap to Connect" — serif italic (matches HTML h2)
            Text(
              'Tap to Connect',
              style: SteelFonts.serif(
                size: 28,
                weight: FontWeight.w400,
              ).copyWith(fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: SteelSpacing.md),

            // Subtitle with current privacy mode
            Text(
              isSimulateMode
                  ? 'Simulate NFC tap-to-share'
                  : 'Bring phones together to share',
              style: SteelFonts.caption,
            ),

            const SizedBox(height: SteelSpacing.sm),

            // Privacy mode indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: SteelColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(SteelRadius.pill),
              ),
              child: Text(
                privacyMode.displayName,
                style: SteelFonts.badge.copyWith(color: SteelColors.accent),
              ),
            ),

            const SizedBox(height: SteelSpacing.xxl),

            // "Simulate Tap" button — pill shaped, emerald
            SteelButtonPill(
              label: isSimulateMode ? 'Simulate Tap' : 'Start Sharing',
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── SCANNING VIEW ─────────────────────────────────────────────────
// Shown while NFC is actively reading — intensified orb animation.
class _ScanningView extends StatelessWidget {
  final bool isTagDetected;

  const _ScanningView({
    super.key,
    required this.isTagDetected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active orb with scan line
          OrbView(
            size: 256, // Larger when active (matches HTML orb-active w-64)
            isActive: true,
            showScanLine: isTagDetected,
          ),

          const SizedBox(height: SteelSpacing.xxl),

          Text(
            isTagDetected ? 'Steel member detected!' : 'Reading...',
            style: SteelFonts.headline.copyWith(
              color: isTagDetected ? SteelColors.accent : SteelColors.text,
            ),
          ),

          const SizedBox(height: SteelSpacing.md),

          if (!isTagDetected)
            Text(
              'Hold your phone near a Steel card',
              style: SteelFonts.caption,
            ),
        ],
      ),
    );
  }
}

// ── ERROR VIEW ────────────────────────────────────────────────────
// Shown when something goes wrong during the flow.
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SteelSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 48,
            ),
            const SizedBox(height: SteelSpacing.lg),
            Text(
              error,
              textAlign: TextAlign.center,
              style: SteelFonts.body,
            ),
            const SizedBox(height: SteelSpacing.xxl),
            SteelButton(
              label: 'Try Again',
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
