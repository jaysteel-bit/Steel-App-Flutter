// Framework-independent wire protocol: usable by Steel and a Flow OS adapter.
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

typedef Json = Map<String, dynamic>;

/// Steel canonical JSON v1: sorted ASCII object keys, integer numbers only,
/// UTF-8 JSON strings, no whitespace. Arrays retain order. Not general JCS.
String canonical(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    if (keys.any((k) => !RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$').hasMatch(k))) {
      throw const FormatException('Non-protocol object key');
    }
    return '{${keys.map((k) => '${jsonEncode(k)}:${canonical(value[k])}').join(',')}}';
  }
  if (value is List) return '[${value.map(canonical).join(',')}]';
  if (value is int && (value < -9007199254740991 || value > 9007199254740991)) {
    throw const FormatException('Integer outside interoperable JSON range');
  }
  if (value == null || value is String || value is bool || value is int) {
    return jsonEncode(value);
  }
  throw const FormatException('Unsupported canonical value');
}

class SignedEnvelope {
  final String payload;
  final String signature;
  const SignedEnvelope(this.payload, this.signature);
  Json get data => jsonDecode(payload) as Json;
  Json toJson() => {'payload': data, 'signature': signature};
  factory SignedEnvelope.fromJson(Json json) =>
      SignedEnvelope(canonical(json['payload']), json['signature'] as String);
}

abstract interface class IdentitySigner {
  String get identityId;
  String get keyId;
  Future<SimplePublicKey> get publicKey;
  Future<SignedEnvelope> sign(Json payload);
}

class SoftwareSigner implements IdentitySigner {
  @override
  final String identityId;
  @override
  final String keyId;
  final SimpleKeyPair keyPair;
  SoftwareSigner(this.identityId, this.keyId, this.keyPair);
  static Future<SoftwareSigner> create({String? identityId}) async =>
      SoftwareSigner(
        identityId ?? 'steel:${const Uuid().v4()}',
        'key:${const Uuid().v4()}',
        await Ed25519().newKeyPair(),
      );
  @override
  Future<SimplePublicKey> get publicKey => keyPair.extractPublicKey();
  @override
  Future<SignedEnvelope> sign(Json payload) async {
    final encoded = canonical(payload);
    final sig = await Ed25519().sign(
      utf8.encode('steel-envelope-v1\n$encoded'),
      keyPair: keyPair,
    );
    return SignedEnvelope(encoded, base64UrlEncode(sig.bytes));
  }
}

abstract interface class TrustRegistry {
  Future<SimplePublicKey?> activeKey(String identityId, String keyId);
  Future<bool> isGrantRevoked(String reference, String grantId);
  Future<bool> consumeChallenge(
    String audience,
    String grantId,
    String nonce,
    int now,
  );
}

/// Local verifier only. Restart loses challenges and enrollments. Never use as
/// a production registry; authoritative enrollment and atomic storage required.
class LocalRegistry implements TrustRegistry {
  final Map<String, SimplePublicKey> keys = {};
  final Set<String> revokedGrants = {};
  final Map<String, int> _challenges = {};
  Future<void> enroll(IdentitySigner signer) async {
    keys['${signer.identityId}/${signer.keyId}'] = await signer.publicKey;
  }

  void retireKey(String identityId, String keyId) =>
      keys.remove('$identityId/$keyId');
  String challenge(String audience, String grantId, int now) {
    final nonce = const Uuid().v4();
    _challenges['$audience/$grantId/$nonce'] = now + 60;
    return nonce;
  }

  @override
  Future<SimplePublicKey?> activeKey(String identityId, String keyId) async =>
      keys['$identityId/$keyId'];
  @override
  Future<bool> isGrantRevoked(String reference, String grantId) async =>
      reference != 'local:steel' || revokedGrants.contains(grantId);
  @override
  Future<bool> consumeChallenge(
    String audience,
    String grantId,
    String nonce,
    int now,
  ) async {
    final expiry = _challenges.remove('$audience/$grantId/$nonce');
    return expiry != null && now < expiry;
  }
}

class ProtocolVerifier {
  final TrustRegistry registry;
  ProtocolVerifier(this.registry);
  Never _deny() => throw const FormatException('Proof or authority rejected');
  Future<Json> _verify(
    SignedEnvelope envelope,
    SimplePublicKey key,
    String purpose,
    String audience,
    int now,
  ) async {
    final d = envelope.data;
    if (d['version'] != 1 ||
        d['purpose'] != purpose ||
        d['audience'] != audience ||
        d['issuedAt'] is! int ||
        d['expiresAt'] is! int ||
        d['issuedAt'] > now ||
        now >= d['expiresAt'] ||
        d['issuedAt'] >= d['expiresAt']) {
      _deny();
    }
    if (!await Ed25519().verify(
      utf8.encode('steel-envelope-v1\n${canonical(d)}'),
      signature: Signature(
        base64Url.decode(envelope.signature),
        publicKey: key,
      ),
    )) {
      _deny();
    }
    return d;
  }

  Future<Json> _root(
    SignedEnvelope e,
    String purpose,
    String audience,
    int now,
  ) async {
    final d = e.data;
    if (d['issuer'] is! String || d['keyId'] is! String) _deny();
    final key = await registry.activeKey(d['issuer'], d['keyId']);
    if (key == null) _deny();
    return _verify(e, key, purpose, audience, now);
  }

  Future<Json> profile(SignedEnvelope e, String audience, int now) async {
    final d = await _root(e, 'public-profile', audience, now);
    if (d['profile'] is! Json) _deny();
    return d['profile'] as Json;
  }

  /// Returns only verified signed public data. No caller-provided private data.
  Future<Json> readPublicProfile({
    required SignedEnvelope grant,
    required SignedEnvelope request,
    required SignedEnvelope proof,
    required String audience,
    required int now,
  }) async {
    final g = await _root(grant, 'automation-grant', audience, now);
    if (g['grantId'] is! String ||
        g['revocationRef'] is! String ||
        await registry.isGrantRevoked(g['revocationRef'], g['grantId'])) {
      _deny();
    }
    final delegate = SimplePublicKey(
      base64Url.decode(g['delegateKey']),
      type: KeyPairType.ed25519,
    );
    final r = await _verify(request, delegate, 'action-request', audience, now);
    if (r['issuer'] != g['issuer'] ||
        g['delegateKeyId'] is! String ||
        r['keyId'] != g['delegateKeyId'] ||
        r['grantId'] != g['grantId'] ||
        r['action'] != 'profile.public.read' ||
        g['actions'] is! List ||
        !(g['actions'] as List).contains(r['action']) ||
        r['resource'] != g['resource'] ||
        r['nonce'] is! String ||
        r['issuedAt'] < g['issuedAt'] ||
        r['expiresAt'] > g['expiresAt']) {
      _deny();
    }
    final p = await _root(proof, 'public-profile', audience, now);
    if (p['issuer'] != g['issuer'] ||
        p['resource'] != g['resource'] ||
        p['profile'] is! Json) {
      _deny();
    }
    if (!await registry.consumeChallenge(
      audience,
      g['grantId'],
      r['nonce'],
      now,
    )) {
      _deny();
    }
    return p['profile'] as Json;
  }
}

Json metadata(
  IdentitySigner signer,
  String purpose,
  String audience,
  int now, {
  int ttl = 300,
}) => {
  'version': 1,
  'issuer': signer.identityId,
  'keyId': signer.keyId,
  'purpose': purpose,
  'audience': audience,
  'issuedAt': now,
  'expiresAt': now + ttl,
};

Future<String> automationDemo(IdentitySigner owner, Json publicProfile) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  const audience = 'steel:local-demo';
  final registry = LocalRegistry();
  await registry.enroll(owner);
  final verifier = ProtocolVerifier(registry);
  final delegate = await SoftwareSigner.create();
  final resource = 'personal:${owner.identityId}/public-profile';
  final grantId = const Uuid().v4();
  final proof = await owner.sign({
    ...metadata(owner, 'public-profile', audience, now),
    'resource': resource,
    'profile': publicProfile,
  });
  final grant = await owner.sign({
    ...metadata(owner, 'automation-grant', audience, now),
    'grantId': grantId,
    'delegateKey': base64UrlEncode((await delegate.publicKey).bytes),
    'delegateKeyId': delegate.keyId,
    'actions': ['profile.public.read'],
    'resource': resource,
    'revocationRef': 'local:steel',
  });
  final request = await delegate.sign({
    ...metadata(owner, 'action-request', audience, now, ttl: 60),
    'keyId': delegate.keyId,
    'grantId': grantId,
    'action': 'profile.public.read',
    'resource': resource,
    'nonce': registry.challenge(audience, grantId, now),
  });
  final result = await verifier.readPublicProfile(
    grant: grant,
    request: request,
    proof: proof,
    audience: audience,
    now: now,
  );
  var replayBlocked = false;
  try {
    await verifier.readPublicProfile(
      grant: grant,
      request: request,
      proof: proof,
      audience: audience,
      now: now,
    );
  } on FormatException {
    replayBlocked = true;
  }
  return 'Signed public read verified for ${result['name']}. Replay blocked: $replayBlocked. '
      'Grant limited to profile.public.read; local registry only.';
}
