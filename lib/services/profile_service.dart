// profile_service.dart
// Steel by Exo — Profile Service (Flutter)
//
// Ported from ProfileService.swift (iOS version).
// Handles fetching and managing Steel member profiles.
//
// BACKEND INTEGRATION:
//   GET  /api/profiles/{profileSlug}?sid={shareId}  → fetch public profile
//   POST /api/nfc/share                              → log share event
//   POST /api/connections/request                    → non-member connect back
//
// For MVP: Returns mock data. Production: Connects to Supabase/backend.

import 'package:flutter/foundation.dart';
import '../models/steel_profile.dart';
import '../models/steel_connection.dart';

/// Service for fetching profiles and logging NFC share events.
class ProfileService extends ChangeNotifier {

  // ── State ───────────────────────────────────────────────────────
  SteelProfile? _currentProfile;
  bool _isLoading = false;
  String? _lastError;

  SteelProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // ── Configuration ───────────────────────────────────────────────
  // TODO: Replace with actual backend URL in production
  // ignore: unused_field
  final String _baseUrl;

  ProfileService({
    String baseUrl = 'https://api.steel.app',
  }) : _baseUrl = baseUrl;

  // ── Fetch Profile ───────────────────────────────────────────────

  /// Fetch a member's public profile by their Steel ID.
  /// This is called after NFC tag is read to show the sharer's profile.
  ///
  /// In PUBLIC mode: Called immediately after tag read.
  /// In PRIVATE mode: Called after PIN verification succeeds.
  Future<SteelProfile?> fetchProfile(String memberId) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // ── STUB MODE: Return mock data ──
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
      _currentProfile = SteelProfile.mock;
      _isLoading = false;
      notifyListeners();
      return _currentProfile;

      // ── PRODUCTION CODE ──
      // final response = await http.get(
      //   Uri.parse('$_baseUrl/api/profiles/$memberId'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   _currentProfile = SteelProfile.fromJson(data);
      // }
      // _isLoading = false;
      // notifyListeners();
      // return _currentProfile;

    } catch (e) {
      _lastError = 'Failed to fetch profile: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── Log Share Event ─────────────────────────────────────────────

  /// Log an NFC share event to the backend for viral loop analytics.
  /// Called every time a successful NFC tap-to-share occurs.
  ///
  /// Returns the share event with a tracking URL for the receiver.
  Future<NFCShareEvent?> logShareEvent({
    required String sharerId,
    String? eventId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // ── STUB MODE ──
      final event = NFCShareEvent(
        id: 'share_${DateTime.now().millisecondsSinceEpoch}',
        sharerId: sharerId,
        timestamp: DateTime.now(),
        eventId: eventId,
        latitude: latitude,
        longitude: longitude,
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (kDebugMode) {
        debugPrint('=== STEEL: Logged share event ${event.id} ===');
      }

      return event;

      // ── PRODUCTION CODE ──
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/api/nfc/share'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'sharer_id': sharerId,
      //     'event_id': eventId,
      //     'location': latitude != null ? {'lat': latitude, 'lng': longitude} : null,
      //   }),
      // );
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   return NFCShareEvent.fromJson(data);
      // }
      // return null;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log share event: $e');
      }
      return null;
    }
  }

  // ── Connect Back (Non-member) ───────────────────────────────────

  /// Send a connection request from a non-member who viewed a web profile.
  /// This is the "Connect Back" CTA on the web profile page.
  Future<bool> sendConnectionRequest({
    required String shareId,
    required String recipientEmail,
    String? message,
  }) async {
    try {
      // ── STUB MODE ──
      await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode) {
        debugPrint('=== STEEL: Connection request from $recipientEmail ===');
      }
      return true;

      // ── PRODUCTION CODE ──
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/api/connections/request'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'share_id': shareId,
      //     'recipient_email': recipientEmail,
      //     'message': message,
      //   }),
      // );
      // return response.statusCode == 200;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to send connection request: $e');
      }
      return false;
    }
  }

  /// Clear the current profile (reset state).
  void clearProfile() {
    _currentProfile = null;
    notifyListeners();
  }
}
