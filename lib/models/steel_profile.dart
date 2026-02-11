// steel_profile.dart
// Steel by Exo — User Profile Model (Flutter)
//
// Ported from SteelProfile.swift (iOS version).
// Represents a Steel member's profile data with privacy gradient:
//   PUBLIC:  Name, photo, headline, membership status (shared on tap)
//   PRIVATE: Phone, email, personal socials (requires approval / PIN)

import 'package:flutter/material.dart' show IconData, Icons;

/// Represents a Steel member's complete profile.
class SteelProfile {
  final String id;             // Unique member ID (stored on NFC tag)
  final String firstName;
  final String lastName;
  final String headline;       // e.g. "Creative Director | NYC"
  final String? bio;
  final String? avatarURL;     // URL to profile photo
  final MembershipTier membershipTier;

  // Public layer — shared immediately on NFC tap
  final List<SocialLink> publicSocials;

  // Private layer — requires explicit approval
  final String? phoneNumber;
  final String? email;
  final List<SocialLink> privateSocials;

  SteelProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.headline,
    this.bio,
    this.avatarURL,
    required this.membershipTier,
    required this.publicSocials,
    this.phoneNumber,
    this.email,
    this.privateSocials = const [],
  });

  String get fullName => '$firstName $lastName';
  String get displayName => fullName;

  /// Create from JSON (API response).
  factory SteelProfile.fromJson(Map<String, dynamic> json) {
    return SteelProfile(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      headline: json['headline'] as String,
      bio: json['bio'] as String?,
      avatarURL: json['avatarURL'] as String?,
      membershipTier: MembershipTier.fromString(json['membershipTier'] as String? ?? 'digital'),
      publicSocials: (json['publicSocials'] as List<dynamic>?)
          ?.map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      privateSocials: (json['privateSocials'] as List<dynamic>?)
          ?.map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Convert to JSON (for API requests).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'headline': headline,
      'bio': bio,
      'avatarURL': avatarURL,
      'membershipTier': membershipTier.value,
      'publicSocials': publicSocials.map((e) => e.toJson()).toList(),
      'phoneNumber': phoneNumber,
      'email': email,
      'privateSocials': privateSocials.map((e) => e.toJson()).toList(),
    };
  }

  /// Mock data for development — matches steel.html's "Alexa Rivera" profile.
  static final mock = SteelProfile(
    id: 'steel_001',
    firstName: 'Alexa',
    lastName: 'Rivera',
    headline: 'Creative Director | NYC',
    bio: 'Building the future of digital identity and curated experiences.',
    avatarURL: 'https://randomuser.me/api/portraits/men/32.jpg',
    membershipTier: MembershipTier.steel,
    publicSocials: [
      SocialLink(platform: SocialPlatform.instagram, handle: '@alexa.rivera'),
      SocialLink(platform: SocialPlatform.linkedin, handle: 'LinkedIn'),
      SocialLink(platform: SocialPlatform.phone, handle: 'Contact'),
    ],
    phoneNumber: '+1 (555) 123-4567',
    email: 'alex@exo.dev',
    privateSocials: [
      SocialLink(platform: SocialPlatform.twitter, handle: '@alexr_creates'),
    ],
  );
}

/// Steel membership tiers — maps to the tier system from product docs.
enum MembershipTier {
  digital('digital', 'Steel Digital'),
  steel('steel', 'Steel Member'),
  elite('elite', 'Steel Elite');

  final String value;
  final String displayName;
  const MembershipTier(this.value, this.displayName);

  static MembershipTier fromString(String value) {
    return MembershipTier.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MembershipTier.digital,
    );
  }
}

/// A single social media or contact link.
/// The HTML prototype shows Instagram, LinkedIn, and Phone as three columns.
class SocialLink {
  final String id;
  final SocialPlatform platform;
  final String handle;       // e.g. "@alex.rivera"
  final String? url;         // Full URL if applicable

  SocialLink({
    String? id,
    required this.platform,
    required this.handle,
    this.url,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: json['id'] as String?,
      platform: SocialPlatform.fromString(json['platform'] as String),
      handle: json['handle'] as String,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform.value,
    'handle': handle,
    'url': url,
  };
}

/// Supported social platforms.
/// Maps to lucide icons in the HTML → Material Icons in Flutter.
enum SocialPlatform {
  instagram('instagram', 'Instagram'),
  linkedin('linkedin', 'LinkedIn'),
  twitter('twitter', 'X'),
  phone('phone', 'Contact'),
  email('email', 'Email'),
  website('website', 'Website');

  final String value;
  final String displayName;

  const SocialPlatform(this.value, this.displayName);

  /// Get the Material icon for this platform.
  IconData get icon {
    switch (this) {
      case SocialPlatform.instagram: return Icons.camera_alt;
      case SocialPlatform.linkedin: return Icons.work;
      case SocialPlatform.twitter: return Icons.alternate_email;
      case SocialPlatform.phone: return Icons.phone;
      case SocialPlatform.email: return Icons.email;
      case SocialPlatform.website: return Icons.language;
    }
  }

  static SocialPlatform fromString(String value) {
    return SocialPlatform.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SocialPlatform.website,
    );
  }
}

