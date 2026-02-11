// verification_view.dart
// Steel by Exo — PIN Verification Screen
//
// Ported from VerificationView.swift (iOS) + #verification state in steel.html.
// Shows when a user is in PRIVATE mode and needs to enter the 4-digit PIN:
//   - 4 PIN fields that fill with emerald color as digits are entered
//   - Scan line animation across the active orb
//   - "Verifying secure access..." text
//   - Auto-submits when all 4 digits are entered
//
// Matches the GSAP timeline: pin-field fills → scan line sweep → verify → reveal

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/steel_theme.dart';
import '../../models/verification_state.dart';
import '../../providers/providers.dart';
import '../components/orb_view.dart';

class VerificationView extends ConsumerStatefulWidget {
  final String sharerId;
  final VoidCallback onVerified;
  final VoidCallback onCancel;

  const VerificationView({
    super.key,
    required this.sharerId,
    required this.onVerified,
    required this.onCancel,
  });

  @override
  ConsumerState<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends ConsumerState<VerificationView> {
  final PINState _pinState = PINState();
  bool _isVerifying = false;
  String? _errorMessage;

  /// Handle digit input from the number pad.
  void _onDigitPressed(int digit) {
    if (_pinState.isComplete || _isVerifying) return;

    setState(() {
      _pinState.appendDigit(digit);
      _errorMessage = null;
    });

    // Haptic feedback for each digit
    HapticFeedback.lightImpact();

    // Auto-submit when all 4 digits are entered
    if (_pinState.isComplete) {
      _verifyPIN();
    }
  }

  /// Handle backspace — remove last digit.
  void _onBackspace() {
    if (_isVerifying) return;
    setState(() {
      _pinState.removeLastDigit();
      _errorMessage = null;
    });
    HapticFeedback.selectionClick();
  }

  /// Verify the entered PIN against the backend.
  Future<void> _verifyPIN() async {
    setState(() => _isVerifying = true);

    final smsService = ref.read(smsVerificationServiceProvider);
    final isValid = await smsService.verifyPIN(widget.sharerId, _pinState.pinString);

    if (isValid) {
      HapticFeedback.heavyImpact();
      ref.read(verificationStateProvider.notifier).state = VerificationFlowState.verified;
      widget.onVerified();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _pinState.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SteelSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active orb with scan line
          const OrbView(
            size: 200,
            isActive: true,
            showScanLine: true,
          ),

          const SizedBox(height: SteelSpacing.xxl),

          // PIN Fields — 4 boxes that fill with emerald
          // Matches HTML: .pin-field w-12 h-12 bg-brand-gray rounded-lg border-2
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = _pinState.digits[index] != null;
              final isNext = index == _pinState.enteredCount;

              return AnimatedContainer(
                duration: SteelAnimation.quick,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  // Matches GSAP: backgroundColor: '#10b981' when filled
                  color: isFilled ? SteelColors.accent : SteelColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(SteelRadius.small),
                  border: Border.all(
                    color: isNext
                        ? SteelColors.accent
                        : isFilled
                            ? SteelColors.accent
                            : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isFilled
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: SteelSpacing.lg),

          // Status text
          Text(
            _isVerifying
                ? 'Verifying secure access...'
                : _errorMessage ?? 'Enter the PIN shown on the sharer\'s phone',
            style: SteelFonts.caption.copyWith(
              color: _errorMessage != null ? Colors.red.shade400 : SteelColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: SteelSpacing.xxl),

          // Number pad
          _NumberPad(
            onDigitPressed: _onDigitPressed,
            onBackspace: _onBackspace,
            isEnabled: !_isVerifying,
          ),

          const SizedBox(height: SteelSpacing.lg),

          // Cancel button
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'Cancel',
              style: SteelFonts.caption.copyWith(color: SteelColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple number pad for PIN entry.
class _NumberPad extends StatelessWidget {
  final void Function(int digit) onDigitPressed;
  final VoidCallback onBackspace;
  final bool isEnabled;

  const _NumberPad({
    required this.onDigitPressed,
    required this.onBackspace,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow([1, 2, 3]),
        const SizedBox(height: 12),
        _buildRow([4, 5, 6]),
        const SizedBox(height: 12),
        _buildRow([7, 8, 9]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty space (left)
            const SizedBox(width: 72, height: 56),
            const SizedBox(width: 12),
            // Zero
            _DigitButton(
              digit: 0,
              onPressed: isEnabled ? () => onDigitPressed(0) : null,
            ),
            const SizedBox(width: 12),
            // Backspace
            SizedBox(
              width: 72,
              height: 56,
              child: TextButton(
                onPressed: isEnabled ? onBackspace : null,
                child: Icon(
                  Icons.backspace_outlined,
                  color: SteelColors.textMuted,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _DigitButton(
            digit: d,
            onPressed: isEnabled ? () => onDigitPressed(d) : null,
          ),
        );
      }).toList(),
    );
  }
}

class _DigitButton extends StatelessWidget {
  final int digit;
  final VoidCallback? onPressed;

  const _DigitButton({required this.digit, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 56,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: SteelColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SteelRadius.medium),
          ),
        ),
        child: Text(
          '$digit',
          style: SteelFonts.sans(
            size: 24,
            weight: FontWeight.w500,
            color: SteelColors.text,
          ),
        ),
      ),
    );
  }
}
