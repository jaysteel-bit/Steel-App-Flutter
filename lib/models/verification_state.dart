// verification_state.dart
// Steel by Exo — Verification Flow State (Flutter)
//
// Ported from VerificationState.swift (iOS version).
// Tracks the NFC tap → verify → reveal flow.
// Maps to the HTML prototype's three visual states:
//   1. IDLE:      Orb + "Tap to Connect" button
//   2. SCANNING:  Active orb + PIN fields filling + scan line
//   3. REVEALED:  Glass card with full profile data

/// Top-level state machine for the NFC tap → verify → reveal flow.
enum VerificationFlowState {
  idle,               // Waiting for NFC tap (shows locked orb)
  scanning,           // NFC session active, reading tag
  tagDetected,        // Tag read, loading sharer info
  pinEntry,           // Waiting for user to enter PIN (private mode)
  verifying,          // PIN submitted, checking with backend
  verified,           // PIN correct — transitioning to profile
  profileRevealed,    // Profile card visible with full data
  error,              // Something went wrong
}

/// Specific errors that can occur during verification.
enum VerificationError {
  nfcNotAvailable('NFC is not available on this device.'),
  tagReadFailed("Couldn't read the Steel tag. Try again."),
  invalidTag("This doesn't appear to be a valid Steel tag."),
  pinIncorrect('Incorrect PIN. Please check with the sharer.'),
  pinExpired('Verification timed out. Tap again to retry.'),
  networkError('Connection error. Please check your network.'),
  sharerDeclined('The sharer has declined this connection.');

  final String message;
  const VerificationError(this.message);
}

/// Tracks the 4-digit PIN entry progress.
/// Each digit fills one of the four fields shown in the HTML prototype.
class PINState {
  List<int?> digits;

  PINState() : digits = List.filled(4, null);

  /// How many digits have been entered so far.
  int get enteredCount => digits.where((d) => d != null).length;

  /// Whether all 4 digits have been entered.
  bool get isComplete => enteredCount == 4;

  /// Get the full PIN as a string (e.g. "1234").
  String get pinString => digits.whereType<int>().map((d) => d.toString()).join();

  /// Add a digit to the next empty slot.
  void appendDigit(int digit) {
    final firstEmpty = digits.indexWhere((d) => d == null);
    if (firstEmpty != -1) {
      digits[firstEmpty] = digit;
    }
  }

  /// Remove the last entered digit.
  void removeLastDigit() {
    final lastFilled = digits.lastIndexWhere((d) => d != null);
    if (lastFilled != -1) {
      digits[lastFilled] = null;
    }
  }

  /// Reset all digits.
  void clear() {
    digits = List.filled(4, null);
  }
}

/// Privacy mode — controls how NFC shares behave.
/// From the Perplexity hybrid spec: users choose their privacy level.
enum PrivacyMode {
  /// One-tap share, no PIN required.
  /// Best for: Events, networking, growth.
  public_('public', 'Public Mode', 'One-tap share, no PIN required'),

  /// SMS PIN required for every share.
  /// Best for: Personal, high-security.
  private_('private', 'Private Mode', 'SMS PIN required for every share'),

  /// PIN only for first tap at an event, then all subsequent taps approved.
  /// Best for: Conferences, meetups.
  event('event', 'Event Mode', 'PIN for first tap, then free sharing');

  final String value;
  final String displayName;
  final String description;
  const PrivacyMode(this.value, this.displayName, this.description);
}
