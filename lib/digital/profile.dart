import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../identity/protocol.dart';

class DigitalProfile {
  final String name, headline, instagram, linkedin, phone, privateEmail;
  final bool publishPhone;
  const DigitalProfile({
    this.name = 'Alexis Rivera',
    this.headline = 'Creative Director | NYC',
    this.instagram = 'alexis.rivera',
    this.linkedin = '',
    this.phone = '',
    this.privateEmail = '',
    this.publishPhone = false,
  });
  Json get publicData => {
    'name': name,
    'headline': headline,
    'instagram': instagram,
    'linkedin': linkedin,
    if (publishPhone) 'phone': phone,
  };
  Json get ownerData => {
    ...publicData,
    'phone': phone,
    'privateEmail': privateEmail,
    'publishPhone': publishPhone,
  };
  factory DigitalProfile.fromJson(Json d) => DigitalProfile(
    name: d['name'] as String? ?? '',
    headline: d['headline'] as String? ?? '',
    instagram: d['instagram'] as String? ?? '',
    linkedin: d['linkedin'] as String? ?? '',
    phone: d['phone'] as String? ?? '',
    privateEmail: d['privateEmail'] as String? ?? '',
    publishPhone: d['publishPhone'] == true,
  );
  static String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\\n')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\n')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,');
  static String _fold(String line) {
    final out = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final s = String.fromCharCode(rune);
      final length = utf8.encode(s).length;
      if (bytes + length > 75) {
        out.write('\r\n ');
        bytes = 1;
      }
      out.write(s);
      bytes += length;
    }
    return out.toString();
  }

  String get vCard => [
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:${_escape(name)}',
    'NOTE:${_escape(headline)}',
    if (publishPhone && phone.isNotEmpty) 'TEL:${_escape(phone)}',
    if (instagram.isNotEmpty)
      'URL:https://www.instagram.com/${Uri.encodeComponent(instagram)}/',
    if (linkedin.isNotEmpty) 'URL:${_escape(linkedin)}',
    'END:VCARD',
    '',
  ].map(_fold).join('\r\n');
}

class ProfileRepository {
  static const key = 'steel.digital-profile.v1';
  Future<DigitalProfile> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    return raw == null
        ? const DigitalProfile()
        : DigitalProfile.fromJson(jsonDecode(raw) as Json);
  }

  Future<void> save(DigitalProfile profile) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode(profile.ownerData),
    )) {
      throw StateError('Profile could not be saved');
    }
  }
}
