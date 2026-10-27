import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steel_flutter/digital/profile.dart';

void main() {
  test(
    'owner edits survive reload while visitor projection filters private fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = ProfileRepository();
      await repository.save(
        const DigitalProfile(
          name: 'Jay',
          phone: '+15551234567',
          privateEmail: 'private@example.test',
        ),
      );
      final loaded = await repository.load();
      expect(loaded.name, 'Jay');
      expect(loaded.phone, '+15551234567');
      expect(loaded.privateEmail, 'private@example.test');
      expect(loaded.publicData.containsKey('privateEmail'), false);
      expect(loaded.publicData.containsKey('phone'), false);
      expect(loaded.vCard.contains('TEL:'), false);
      expect(loaded.vCard.contains('EMAIL:'), false);
    },
  );
  test('vCard escapes injection and includes explicitly published phone', () {
    const p = DigitalProfile(
      name: 'Jay\r\nEMAIL:injected',
      phone: '+15551234567',
      publishPhone: true,
    );
    expect(p.vCard, contains('FN:Jay\\nEMAIL:injected\r\n'));
    expect(p.vCard, contains('\r\nTEL:+15551234567\r\n'));
    expect(p.vCard, startsWith('BEGIN:VCARD\r\nVERSION:3.0'));
    expect(p.vCard, endsWith('END:VCARD\r\n'));
  });
}
