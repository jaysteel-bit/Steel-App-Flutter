import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:steel_flutter/identity/key_store.dart';
import 'package:steel_flutter/identity/protocol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'secure-store reload preserves identity and signing control; initialization deduplicates',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureIdentityKeyStore();
      final first = store.loadOrCreate();
      final concurrent = store.loadOrCreate();
      expect(identical(first, concurrent), true);
      final signer = await first;
      final reloaded = await SecureIdentityKeyStore().loadOrCreate();
      expect(reloaded.identityId, signer.identityId);
      expect(reloaded.keyId, signer.keyId);
      final registry = LocalRegistry();
      await registry.enroll(signer);
      final proof = await reloaded.sign({
        ...metadata(reloaded, 'public-profile', 'test', 1000),
        'profile': {'name': 'Test'},
      });
      expect(await ProtocolVerifier(registry).profile(proof, 'test', 1000), {
        'name': 'Test',
      });
    },
  );
}
