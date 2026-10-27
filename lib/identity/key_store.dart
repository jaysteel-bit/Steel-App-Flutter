import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'protocol.dart';

abstract interface class IdentityKeyStore {
  Future<IdentitySigner> loadOrCreate();
}

/// Exportable Ed25519 seed in OS secure storage, NOT a hardware-bound key.
/// Web storage is experimental, origin-bound, and vulnerable to same-origin JS.
/// Never fall back to ordinary preferences when secure storage fails.
class SecureIdentityKeyStore implements IdentityKeyStore {
  final FlutterSecureStorage storage;
  SecureIdentityKeyStore({
    this.storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  });
  Future<IdentitySigner>? _pending;
  @override
  Future<IdentitySigner> loadOrCreate() => _pending ??= _load();
  Future<IdentitySigner> _load() async {
    final saved = await storage.read(key: 'steel.identity.v1');
    if (saved == null && await storage.containsKey(key: 'steel.identity.v1')) {
      throw StateError('Existing identity could not be decrypted');
    }
    if (saved != null) {
      final d = jsonDecode(saved) as Json;
      return SoftwareSigner(
        d['identityId'],
        d['keyId'],
        await Ed25519().newKeyPairFromSeed(base64Url.decode(d['seed'])),
      );
    }
    final signer = await SoftwareSigner.create();
    final record = jsonEncode({
      'identityId': signer.identityId,
      'keyId': signer.keyId,
      'seed': base64UrlEncode(await signer.keyPair.extractPrivateKeyBytes()),
    });
    await storage.write(key: 'steel.identity.v1', value: record);
    if (await storage.read(key: 'steel.identity.v1') != record) {
      throw StateError('Identity persistence verification failed');
    }
    return signer;
  }
}

/// Future adapters must authenticate rotation and invalidate old keys/grants
/// atomically in the authority registry. No working recovery is claimed.
abstract interface class IdentityLifecycle {
  Future<void> rotate(IdentitySigner current);
  Future<void> recover(String identityId);
}
