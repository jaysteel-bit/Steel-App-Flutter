// providers.dart
// Steel by Exo — Riverpod Providers
//
// Central provider definitions for the app's services and state.
// Using Riverpod for reactive, testable state management.
//
// Usage in widgets:
//   final nfc = ref.watch(nfcServiceProvider);
//   final profile = ref.watch(profileServiceProvider);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/nfc_service.dart';
import '../services/sms_verification_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../models/verification_state.dart';

// ── Service Providers ─────────────────────────────────────────────

/// NFC service — singleton for the app lifecycle.
final nfcServiceProvider = ChangeNotifierProvider<NFCService>((ref) {
  return NFCService();
});

/// SMS verification service — singleton.
final smsVerificationServiceProvider = ChangeNotifierProvider<SMSVerificationService>((ref) {
  return SMSVerificationService();
});

/// Profile service — singleton.
final profileServiceProvider = ChangeNotifierProvider<ProfileService>((ref) {
  return ProfileService();
});

/// Auth service — singleton.
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

// ── State Providers ───────────────────────────────────────────────

/// Current verification flow state.
final verificationStateProvider = StateProvider<VerificationFlowState>((ref) {
  return VerificationFlowState.idle;
});

/// Current privacy mode setting.
final privacyModeProvider = StateProvider<PrivacyMode>((ref) {
  return PrivacyMode.public_; // Default to public for viral growth (Option 3 hybrid)
});

/// Whether the app is in simulate mode (no real NFC hardware).
final simulateModeProvider = StateProvider<bool>((ref) {
  return true; // Default to true for development
});
