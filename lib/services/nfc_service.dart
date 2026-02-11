// nfc_service.dart
// Steel by Exo — NFC Service (Flutter)
//
// Ported from NFCService.swift (iOS version).
// Handles all NFC operations using the nfc_manager package:
//   - READING: Scan Steel tags to extract sharer ID + name
//   - WRITING: Write NDEF records to tags (member setup + viral URL share)
//
// NDEF TAG STRUCTURE (from product docs):
//   Record 1: URI    → steel.app/p/{profileSlug}?src=nfc&uid={userId}&ts={timestamp}
//   Record 2: Text   → Sharer name (basic vCard-like info)
//   Record 3: Custom → com.exo.steel:connect (app-specific encrypted data)
//
// HYBRID FLOW (from Perplexity spec):
//   Public Mode:  Write URL → one-tap share → web/app opens instantly
//   Private Mode: Read tag → extract ID → trigger SMS PIN verification
//   Event Mode:   PIN on first tap, then public for rest of event
//
// PLATFORM NOTES:
//   - Android: Uses nfc_manager (NfcA/NfcB/Ndef). Requires permissions in AndroidManifest.xml.
//   - iOS: Uses nfc_manager (CoreNFC wrapper). Requires entitlements + Info.plist.
//   - Web: NFC not available. Falls back to QR code or manual URL entry.
//          (Web NFC API is experimental and Chrome-only, not reliable for MVP.)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/verification_state.dart';

/// Service that manages all NFC read/write operations for Steel.
/// Uses ChangeNotifier so Flutter widgets can react to NFC state changes.
class NFCService extends ChangeNotifier {

  // ── Published State ─────────────────────────────────────────────
  String? _lastReadSharerID;
  String? _lastReadSharerName;
  bool _isScanning = false;
  String? _lastError;
  bool _isSimulateMode = false; // For development/web where NFC isn't available

  String? get lastReadSharerID => _lastReadSharerID;
  String? get lastReadSharerName => _lastReadSharerName;
  bool get isScanning => _isScanning;
  String? get lastError => _lastError;
  bool get isSimulateMode => _isSimulateMode;

  /// Check if NFC is available on this device.
  /// Returns false on web, simulator, and devices without NFC hardware.
  Future<bool> isNFCAvailable() async {
    // On web, NFC is not supported
    if (kIsWeb) return false;

    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Enable simulate mode for development/web testing.
  /// When enabled, beginScanning() returns mock data instead of using real NFC.
  void enableSimulateMode() {
    _isSimulateMode = true;
    notifyListeners();
  }

  // ── READING ─────────────────────────────────────────────────────

  /// Start scanning for a Steel NFC tag.
  /// On Android/iOS: Starts the NFC reader session.
  /// In simulate mode: Returns mock data after a brief delay (mimics real NFC timing).
  ///
  /// Returns the sharer's member ID on success.
  Future<String?> beginScanning() async {
    _lastError = null;
    _isScanning = true;
    notifyListeners();

    // ── Simulate Mode ──
    // Used in development, web, and devices without NFC.
    // Simulates the full NFC tap experience with realistic timing.
    if (_isSimulateMode || kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate tap delay
      _lastReadSharerID = 'steel_001';
      _lastReadSharerName = 'Alexa Rivera';
      _isScanning = false;
      notifyListeners();
      return _lastReadSharerID;
    }

    // ── Real NFC ──
    final available = await isNFCAvailable();
    if (!available) {
      _lastError = 'NFC is not available on this device.';
      _isScanning = false;
      notifyListeners();
      return null;
    }

    try {
      String? result;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              _lastError = 'This tag is not NDEF compatible.';
              _isScanning = false;
              notifyListeners();
              await NfcManager.instance.stopSession(errorMessage: _lastError);
              return;
            }

            // Read the NDEF message
            final message = await ndef.read();
            final parsed = _parseSteelMessage(message);

            if (parsed.$1 != null) {
              _lastReadSharerID = parsed.$1;
              _lastReadSharerName = parsed.$2;
              result = parsed.$1;
              await NfcManager.instance.stopSession(alertMessage: 'Steel member detected!');
            } else {
              _lastError = 'Not a valid Steel tag.';
              await NfcManager.instance.stopSession(errorMessage: _lastError);
            }
          } catch (e) {
            _lastError = 'Failed to read tag: $e';
            await NfcManager.instance.stopSession(errorMessage: _lastError);
          }

          _isScanning = false;
          notifyListeners();
        },
      );

      return result;
    } catch (e) {
      _lastError = 'NFC session error: $e';
      _isScanning = false;
      notifyListeners();
      return null;
    }
  }

  /// Stop the current NFC session.
  void stopScanning() {
    if (!kIsWeb && !_isSimulateMode) {
      NfcManager.instance.stopSession();
    }
    _isScanning = false;
    notifyListeners();
  }

  // ── WRITING ─────────────────────────────────────────────────────

  /// Write Steel NDEF records to a tag for viral URL sharing.
  /// This is the core of the one-tap viral loop from the Perplexity spec:
  ///   Person A opens app → "Share Profile" → phone enters NFC write mode
  ///   Person B taps → gets URL notification → opens web profile
  ///
  /// URL format: https://steel.app/p/{profileSlug}?src=nfc&uid={userId}&ts={timestamp}
  Future<bool> writeShareProfile({
    required String userId,
    required String profileSlug,
    required String memberName,
    PrivacyMode privacyMode = PrivacyMode.public_,
  }) async {
    if (_isSimulateMode || kIsWeb) {
      // In simulate mode, just pretend it worked
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    final available = await isNFCAvailable();
    if (!available) {
      _lastError = 'NFC is not available on this device.';
      notifyListeners();
      return false;
    }

    try {
      bool success = false;

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            _lastError = "Couldn't write to device.";
            await NfcManager.instance.stopSession(errorMessage: _lastError);
            notifyListeners();
            return;
          }

          // Build the Steel NDEF message
          final message = _buildSteelNDEFMessage(
            userId: userId,
            profileSlug: profileSlug,
            memberName: memberName,
            privacyMode: privacyMode,
          );

          await ndef.write(message);
          success = true;
          await NfcManager.instance.stopSession(alertMessage: 'Profile shared!');
          notifyListeners();
        },
      );

      return success;
    } catch (e) {
      _lastError = 'NFC write error: $e';
      notifyListeners();
      return false;
    }
  }

  // ── NDEF Message Building ───────────────────────────────────────

  /// Build the NDEF message for Steel's viral URL share.
  /// Record structure matches the iOS NFCService.swift implementation:
  ///   Record 1: URI    → https://steel.app/p/{slug}?src=nfc&uid={id}&ts={timestamp}
  ///   Record 2: Text   → Member name (readable by any NFC device)
  ///   Record 3: External → com.exo.steel:connect (app-specific data with privacy mode)
  NdefMessage _buildSteelNDEFMessage({
    required String userId,
    required String profileSlug,
    required String memberName,
    required PrivacyMode privacyMode,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Record 1: URI — the viral share URL.
    // This is what non-members see when they tap.
    // Opens web profile in browser, or deep links to app if installed.
    final shareUrl = 'https://steel.app/p/$profileSlug?src=nfc&uid=$userId&ts=$timestamp';
    final uriRecord = NdefRecord.createUri(Uri.parse(shareUrl));

    // Record 2: Text — member name.
    // Any phone that reads NFC can show this basic text.
    final textRecord = NdefRecord.createText(memberName);

    // Record 3: External type — app-specific Steel data.
    // Contains the member ID, privacy mode, and timestamp.
    // Only the Steel app knows how to parse this.
    final steelData = jsonEncode({
      'memberId': userId,
      'privacyMode': privacyMode.value,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    });
    final externalRecord = NdefRecord.createExternal(
      'com.exo.steel',
      'connect',
      utf8.encode(steelData),
    );

    return NdefMessage([uriRecord, textRecord, externalRecord]);
  }

  // ── NDEF Parsing ────────────────────────────────────────────────

  /// Parse a Steel NDEF message to extract the sharer's member ID and name.
  /// Returns (sharerId, sharerName) — either can be null if not found.
  (String?, String?) _parseSteelMessage(NdefMessage message) {
    String? sharerId;
    String? sharerName;

    for (final record in message.records) {
      // Check for external type record (com.exo.steel:connect)
      if (record.typeNameFormat == NdefTypeNameFormat.nfcExternal) {
        try {
          final type = utf8.decode(record.type);
          if (type.contains('steel') && type.contains('connect')) {
            final json = jsonDecode(utf8.decode(record.payload)) as Map<String, dynamic>;
            sharerId = json['memberId'] as String?;
          }
        } catch (_) {
          // Not a valid Steel external record, skip
        }
      }

      // Check for URI record (fallback — extract ID from URL path)
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
        final typeStr = utf8.decode(record.type);
        if (typeStr == 'U') {
          // URI record
          final uri = record.payload;
          if (uri.isNotEmpty) {
            try {
              // The first byte of a URI record is the URI identifier code
              // https://en.wikipedia.org/wiki/NFC_Data_Exchange_Format#URI_Record_Type_Definition
              final uriString = _decodeNdefUri(uri);
              if (uriString != null && uriString.contains('steel.app/p/')) {
                final uriObj = Uri.parse(uriString);
                sharerId ??= uriObj.queryParameters['uid'];
              }
            } catch (_) {}
          }
        } else if (typeStr == 'T') {
          // Text record — member name
          if (record.payload.length > 1) {
            final langCodeLength = record.payload[0] & 0x3F;
            if (langCodeLength + 1 < record.payload.length) {
              sharerName = utf8.decode(
                record.payload.sublist(langCodeLength + 1),
              );
            }
          }
        }
      }
    }

    return (sharerId, sharerName);
  }

  /// Decode an NDEF URI record payload.
  /// The first byte is a URI identifier code prefix (e.g., 0x04 = "https://").
  String? _decodeNdefUri(List<int> payload) {
    if (payload.isEmpty) return null;

    const prefixes = {
      0x00: '',
      0x01: 'http://www.',
      0x02: 'https://www.',
      0x03: 'http://',
      0x04: 'https://',
    };

    final prefix = prefixes[payload[0]] ?? '';
    final rest = utf8.decode(payload.sublist(1));
    return '$prefix$rest';
  }
}
