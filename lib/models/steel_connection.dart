// steel_connection.dart
// Steel by Exo — Connection Model (Flutter)
//
// Represents a connection between two Steel members (or member + non-member).
// Logs NFC share events for the viral loop analytics.

/// A logged NFC share event — used for analytics and connection history.
class NFCShareEvent {
  final String id;
  final String sharerId;
  final String? recipientDeviceType;  // 'iOS', 'Android'
  final String? recipientClient;      // 'web', 'app_clip', 'full_app'
  final String? eventId;              // If shared at a specific event
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? sessionId;
  final bool convertedToSignup;
  final bool convertedToConnection;

  NFCShareEvent({
    required this.id,
    required this.sharerId,
    this.recipientDeviceType,
    this.recipientClient,
    this.eventId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.sessionId,
    this.convertedToSignup = false,
    this.convertedToConnection = false,
  });

  factory NFCShareEvent.fromJson(Map<String, dynamic> json) {
    return NFCShareEvent(
      id: json['id'] as String,
      sharerId: json['sharer_id'] as String,
      recipientDeviceType: json['recipient_device_type'] as String?,
      recipientClient: json['recipient_client'] as String?,
      eventId: json['event_id'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sessionId: json['session_id'] as String?,
      convertedToSignup: json['converted_to_signup'] as bool? ?? false,
      convertedToConnection: json['converted_to_connection'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sharer_id': sharerId,
    'recipient_device_type': recipientDeviceType,
    'recipient_client': recipientClient,
    'event_id': eventId,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'session_id': sessionId,
    'converted_to_signup': convertedToSignup,
    'converted_to_connection': convertedToConnection,
  };
}

/// Represents a connection request from a non-member via web profile.
class ConnectionRequest {
  final String shareId;
  final String recipientEmail;
  final String? message;
  final DateTime timestamp;

  ConnectionRequest({
    required this.shareId,
    required this.recipientEmail,
    this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'share_id': shareId,
    'recipient_email': recipientEmail,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}
