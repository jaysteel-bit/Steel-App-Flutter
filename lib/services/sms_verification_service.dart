// sms_verification_service.dart
// Steel by Exo — SMS PIN Verification Service (Flutter)
//
// Ported from SMSVerificationService.swift (iOS version).
// Handles the privacy-first SMS PIN verification flow:
//   1. Person B taps Person A's NFC tag
//   2. Backend sends SMS with 4-digit PIN to Person A's phone
//   3. Person A reads PIN aloud to Person B
//   4. Person B enters PIN in app → profile revealed
//
// This service is used in PRIVATE and EVENT privacy modes.
// In PUBLIC mode, this service is bypassed entirely.
//
// BACKEND INTEGRATION:
//   POST /api/verification/send-pin  → triggers Twilio SMS
//   POST /api/verification/verify    → checks PIN against backend
//
// For MVP: Uses a stub that generates local PINs for development.
// Production: Will use Twilio via backend API (~$0.01/SMS).

import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for SMS PIN verification (privacy mode flow).
class SMSVerificationService extends ChangeNotifier {

  // ── State ───────────────────────────────────────────────────────
  bool _isSending = false;
  bool _isVerifying = false;
  String? _lastError;
  String? _currentPIN; // In production, this lives on the backend only

  bool get isSending => _isSending;
  bool get isVerifying => _isVerifying;
  String? get lastError => _lastError;

  // ── Configuration ───────────────────────────────────────────────
  // TODO: Replace with actual backend URL in production
  // ignore: unused_field
  final String _baseUrl;

  SMSVerificationService({
    String baseUrl = 'https://api.steel.app',
  }) : _baseUrl = baseUrl;

  // ── Send PIN ────────────────────────────────────────────────────

  /// Send a verification PIN to the sharer's phone via SMS.
  /// In production, this calls the backend which triggers Twilio.
  /// In stub mode, generates a local PIN for testing.
  ///
  /// [sharerId] — The Steel member ID of the person being tapped.
  /// Returns true if the PIN was sent successfully.
  Future<bool> sendPIN(String sharerId) async {
    _isSending = true;
    _lastError = null;
    notifyListeners();

    try {
      // ── STUB MODE (Development) ──
      // Generate a random 4-digit PIN locally.
      // In production, this calls:
      //   POST /api/verification/send-pin
      //   Body: { "sharer_id": sharerId }
      //   Response: { "status": "sent", "expires_in": 30 }
      //
      // The actual PIN is stored server-side and sent via Twilio SMS.
      // The app never knows the real PIN — only verifies it via API.

      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      _currentPIN = _generatePIN();

      // In dev mode, print the PIN to console for testing
      if (kDebugMode) {
        debugPrint('=== STEEL DEV: Verification PIN is $_currentPIN ===');
      }

      _isSending = false;
      notifyListeners();
      return true;

      // ── PRODUCTION CODE (uncomment when backend is ready) ──
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/api/verification/send-pin'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'sharer_id': sharerId}),
      // );
      // _isSending = false;
      // notifyListeners();
      // return response.statusCode == 200;

    } catch (e) {
      _lastError = 'Failed to send verification PIN: $e';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  // ── Verify PIN ──────────────────────────────────────────────────

  /// Verify the PIN entered by the receiver.
  /// Returns true if the PIN matches.
  ///
  /// [sharerId] — The Steel member ID of the sharer.
  /// [enteredPIN] — The 4-digit PIN entered by the receiver.
  Future<bool> verifyPIN(String sharerId, String enteredPIN) async {
    _isVerifying = true;
    _lastError = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

      // ── STUB MODE: Compare locally ──
      final isValid = enteredPIN == _currentPIN;

      if (!isValid) {
        _lastError = 'Incorrect PIN. Please check with the sharer.';
      }

      _isVerifying = false;
      notifyListeners();
      return isValid;

      // ── PRODUCTION CODE ──
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/api/verification/verify'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'sharer_id': sharerId,
      //     'pin': enteredPIN,
      //   }),
      // );
      // final data = jsonDecode(response.body);
      // _isVerifying = false;
      // notifyListeners();
      // return data['verified'] == true;

    } catch (e) {
      _lastError = 'Verification failed: $e';
      _isVerifying = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate a random 4-digit PIN for development/testing.
  String _generatePIN() {
    final random = Random();
    return List.generate(4, (_) => random.nextInt(10)).join();
  }
}
