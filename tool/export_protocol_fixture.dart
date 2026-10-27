// Public, deterministic interoperability TEST vectors. Never use these keys.
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:steel_flutter/identity/protocol.dart';

Future<void> main() async {
  final owner = SoftwareSigner(
    'steel:test-identity',
    'key:test-root',
    await Ed25519().newKeyPairFromSeed(List.generate(32, (i) => i)),
  );
  final delegate = SoftwareSigner(
    'steel:test-agent',
    'key:test-agent',
    await Ed25519().newKeyPairFromSeed(List.generate(32, (i) => 255 - i)),
  );
  const now = 1800000000;
  const audience = 'steel:interop-test';
  const resource = 'personal:steel:test-identity/public-profile';
  final proof = await owner.sign({
    ...metadata(owner, 'public-profile', audience, now),
    'resource': resource,
    'profile': {'name': 'Alexis Rivera', 'headline': 'Creative Director | NYC'},
  });
  final grant = await owner.sign({
    ...metadata(owner, 'automation-grant', audience, now),
    'grantId': 'grant:test',
    'delegateKey': base64UrlEncode((await delegate.publicKey).bytes),
    'delegateKeyId': delegate.keyId,
    'actions': ['profile.public.read'],
    'resource': resource,
    'revocationRef': 'local:steel',
  });
  final request = await delegate.sign({
    ...metadata(owner, 'action-request', audience, now, ttl: 60),
    'keyId': delegate.keyId,
    'grantId': 'grant:test',
    'action': 'profile.public.read',
    'resource': resource,
    'nonce': 'test-challenge',
  });
  final fixture = {
    'warning': 'TEST KEYS ONLY. No enrollment or live authority.',
    'now': now,
    'audience': audience,
    'rootPublicKey': base64UrlEncode((await owner.publicKey).bytes),
    'proof': proof.toJson(),
    'grant': grant.toJson(),
    'request': request.toJson(),
    'proofCanonicalSigningText': 'steel-envelope-v1\n${proof.payload}',
  };
  File(
    'DOCUMENTATION/verification/protocol-fixture.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(fixture));
}
