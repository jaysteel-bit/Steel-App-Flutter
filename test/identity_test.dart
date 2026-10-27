import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:steel_flutter/identity/protocol.dart';

void main() {
  const now = 1800000000;
  const audience = 'steel:test';
  late SoftwareSigner owner, delegate, stranger;
  late LocalRegistry registry;
  late ProtocolVerifier verifier;
  late Json grantData, requestData, proofData;
  late SignedEnvelope grant, request, proof;

  Future<Json> read({
    SignedEnvelope? g,
    SignedEnvelope? r,
    SignedEnvelope? p,
    String aud = audience,
    int time = now,
  }) => verifier.readPublicProfile(
    grant: g ?? grant,
    request: r ?? request,
    proof: p ?? proof,
    audience: aud,
    now: time,
  );
  setUp(() async {
    owner = await SoftwareSigner.create();
    delegate = await SoftwareSigner.create();
    stranger = await SoftwareSigner.create();
    registry = LocalRegistry();
    await registry.enroll(owner);
    verifier = ProtocolVerifier(registry);
    proofData = {
      ...metadata(owner, 'public-profile', audience, now),
      'resource': 'personal:123/public-profile',
      'profile': {'name': 'Alexis Rivera'},
    };
    grantData = {
      ...metadata(owner, 'automation-grant', audience, now),
      'grantId': 'grant-1',
      'delegateKey': base64UrlEncode((await delegate.publicKey).bytes),
      'delegateKeyId': delegate.keyId,
      'actions': ['profile.public.read'],
      'resource': proofData['resource'],
      'revocationRef': 'local:steel',
    };
    requestData = {
      ...metadata(owner, 'action-request', audience, now, ttl: 60),
      'keyId': delegate.keyId,
      'grantId': 'grant-1',
      'action': 'profile.public.read',
      'resource': proofData['resource'],
      'nonce': registry.challenge(audience, 'grant-1', now),
    };
    proof = await owner.sign(proofData);
    grant = await owner.sign(grantData);
    request = await delegate.sign(requestData);
  });
  test(
    'serialized profile proof verifies and valid scoped delegate can read',
    () async {
      final roundTrip = SignedEnvelope.fromJson(
        jsonDecode(jsonEncode(proof.toJson())) as Json,
      );
      expect(await verifier.profile(roundTrip, audience, now), {
        'name': 'Alexis Rivera',
      });
      expect(await read(), {'name': 'Alexis Rivera'});
    },
  );
  test('unsigned tampering is rejected', () async {
    final bad = SignedEnvelope(
      canonical({
        ...proofData,
        'profile': {'name': 'Mallory'},
      }),
      proof.signature,
    );
    await expectLater(read(p: bad), throwsFormatException);
  });
  test('wrong root signing key rejected', () async {
    await expectLater(
      read(g: await stranger.sign(grantData)),
      throwsFormatException,
    );
  });
  test('wrong delegate key rejected', () async {
    await expectLater(
      read(r: await stranger.sign(requestData)),
      throwsFormatException,
    );
  });
  test('delegate key identifier must match the grant', () async {
    await expectLater(
      read(r: await delegate.sign({...requestData, 'keyId': 'key:wrong'})),
      throwsFormatException,
    );
  });
  test('wrong purpose rejected even with valid owner signature', () async {
    await expectLater(
      read(g: await owner.sign({...grantData, 'purpose': 'public-profile'})),
      throwsFormatException,
    );
  });
  test('audience cannot cross personal/organization boundary', () async {
    await expectLater(
      read(aud: 'flow-os:organization:123'),
      throwsFormatException,
    );
  });
  test('expired grant rejected at exact expiration', () async {
    await expectLater(
      read(g: await owner.sign({...grantData, 'expiresAt': now})),
      throwsFormatException,
    );
  });
  test('future-issued grants rejected', () async {
    await expectLater(
      read(g: await owner.sign({...grantData, 'issuedAt': now + 1})),
      throwsFormatException,
    );
  });
  test('expired action rejected', () async {
    await expectLater(
      read(r: await delegate.sign({...requestData, 'expiresAt': now})),
      throwsFormatException,
    );
  });
  test('expired public proof rejected', () async {
    await expectLater(
      read(p: await owner.sign({...proofData, 'expiresAt': now})),
      throwsFormatException,
    );
  });
  test('unauthorized action rejected', () async {
    await expectLater(
      read(r: await delegate.sign({...requestData, 'action': 'purchase'})),
      throwsFormatException,
    );
  });
  test('grant must explicitly allow public read', () async {
    await expectLater(
      read(
        g: await owner.sign({
          ...grantData,
          'actions': ['purchase'],
        }),
      ),
      throwsFormatException,
    );
  });
  test('resource cannot escape personal profile scope', () async {
    await expectLater(
      read(
        r: await delegate.sign({
          ...requestData,
          'resource': 'organization:123/secrets',
        }),
      ),
      throwsFormatException,
    );
  });
  test('public proof must match grant resource', () async {
    await expectLater(
      read(
        p: await owner.sign({
          ...proofData,
          'resource': 'personal:other/public-profile',
        }),
      ),
      throwsFormatException,
    );
  });
  test('request is bound to grant', () async {
    await expectLater(
      read(r: await delegate.sign({...requestData, 'grantId': 'grant-2'})),
      throwsFormatException,
    );
  });
  test('request cannot outlive grant', () async {
    await expectLater(
      read(r: await delegate.sign({...requestData, 'expiresAt': now + 301})),
      throwsFormatException,
    );
  });
  test('unissued nonce rejected', () async {
    await expectLater(
      read(r: await delegate.sign({...requestData, 'nonce': 'invented'})),
      throwsFormatException,
    );
  });
  test('replay rejected; failed signature does not consume nonce', () async {
    await expectLater(
      read(r: await stranger.sign(requestData)),
      throwsFormatException,
    );
    await read();
    await expectLater(read(), throwsFormatException);
  });
  test('expired challenge rejected despite fresh request', () async {
    final later = await delegate.sign({
      ...requestData,
      'issuedAt': now + 60,
      'expiresAt': now + 90,
    });
    await expectLater(read(r: later, time: now + 60), throwsFormatException);
  });
  test(
    'revoked grants and unknown revocation authorities fail closed',
    () async {
      registry.revokedGrants.add('grant-1');
      await expectLater(read(), throwsFormatException);
      registry.revokedGrants.clear();
      await expectLater(
        read(
          g: await owner.sign({
            ...grantData,
            'revocationRef': 'remote:unknown',
          }),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'retired key invalidates old proof and grants; identity stable after rotation',
    () async {
      registry.retireKey(owner.identityId, owner.keyId);
      await expectLater(read(), throwsFormatException);
      await expectLater(
        verifier.profile(proof, audience, now),
        throwsFormatException,
      );
      final replacement = await SoftwareSigner.create(
        identityId: owner.identityId,
      );
      await registry.enroll(replacement);
      expect(replacement.identityId, owner.identityId);
      expect(replacement.keyId, isNot(owner.keyId));
      await expectLater(read(), throwsFormatException);
      final fresh = await replacement.sign({
        ...proofData,
        'keyId': replacement.keyId,
      });
      expect(await verifier.profile(fresh, audience, now), {
        'name': 'Alexis Rivera',
      });
    },
  );
  test('canonical bytes ignore object insertion order, retain array order', () {
    expect(
      canonical({
        'z': 1,
        'a': ['x', 'y'],
      }),
      '{"a":["x","y"],"z":1}',
    );
    expect(() => canonical({'unsafe': 1.2}), throwsFormatException);
  });
}
