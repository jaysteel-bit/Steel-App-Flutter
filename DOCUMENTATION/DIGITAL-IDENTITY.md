# Steel digital identity — 2026-10-26

The app now opens directly to the digital profile. Older NFC/auth screens remain
in the repository for a separate hardware lane; they are not the new entry point.

## Run locally

From `C:/Users/viole/Desktop/steel-flutter`:

```powershell
& C:/src/flutter/bin/flutter.bat pub get
& C:/src/flutter/bin/flutter.bat analyze
& C:/src/flutter/bin/flutter.bat test
& C:/src/flutter/bin/flutter.bat run -d edge
```

For a release preview:

```powershell
& C:/src/flutter/bin/flutter.bat build web --no-wasm-dry-run
python -m http.server 8790 --bind 127.0.0.1 --directory build/web
```

Open `http://127.0.0.1:8790/`. Guest-only route:
`http://127.0.0.1:8790/#/public`. This route displays the profile saved in the same
browser/origin. It does not fetch another member's hosted profile. There is no
production profile host. Share public card shares public text, with clipboard
fallback when sharing is unavailable. Add to Contacts exports a real `.vcf`
through platform sharing or browser download. Device import is OS-dependent.
The waitlist button explains that enrollment is not connected; it collects nothing.

Flutter 3.38.9 / Dart 3.10.8 was used. On this Windows installation, plugin setup
initially required symlink privileges. Generated, ignored junctions under
`windows/flutter/ephemeral/.plugin_symlinks` resolved dependency setup without
changing Developer Mode. A new Windows checkout may need symlink support or the
same junction workaround. Bundled Inter and Playfair Display fonts avoid runtime
font requests; licenses are included. Lucide 0.344.0 SVGs match the HTML reference.

## Product and privacy

`lib/digital/digital_app.dart` renders the HTML fixture and a data-bound card.
The original portrait is bundled locally. A 384px desktop shell surrounds the
318px card; mobile displays the card directly. The portrait is 128px, card radius
16px, border 10% white, fill 5% white and blur 12px. The reveal/lock control is a
presentation state, not an authentication or NFC success claim.

`DigitalProfile.publicData` explicitly projects name, headline, configured social
links and an opted-in phone. Private email and an unshared phone are excluded
from proofs, automation reads, shared text, public rendering and vCards. Owner
data persists in ordinary local preferences, so the private fields are only
hidden from visitors, not encrypted against access to the browser/device.
The portrait is a reference fixture, not yet an editable personal photo.
Membership text is reference artwork, not evidence of issued membership.

## Cryptographic protocol

`lib/identity/protocol.dart` contains no Flutter imports. Signing, verification,
trust lookup, replay protection and lifecycle adapters are separate from UI.
`IdentitySigner`, `IdentityKeyStore`, `TrustRegistry`, and `IdentityLifecycle`
are the replacement points for an authenticated backend or hardware key adapter.

Stable identity ID: `steel:<UUID>`, randomly allocated once at self-enrollment.
Signing key ID: a separate `key:<UUID>`. Neither is a legal identity claim.
The local verifier explicitly enrolls a public key under an identity and key ID;
it does not trust a key just because it arrived in a card. Production enrollment
must authenticate the account and issue an authoritative identity/key binding.

Envelopes serialize as `{payload: <object>, signature: <base64url Ed25519 signature>}`.
Signatures cover UTF-8 `steel-envelope-v1\n` followed by canonical JSON v1:
ASCII object keys matching `[a-zA-Z][a-zA-Z0-9]*` sorted lexicographically,
JSON strings/booleans/null, safe integers only (absolute value <= 2^53-1),
arrays in original order, and no whitespace. This is a constrained Steel
encoding, not a claim to implement general RFC 8785/JCS. Do not Unicode-normalize
strings after signing. Transport parsing and schema hardening need a production
review before accepting arbitrary hostile large envelopes.

Every envelope includes `version=1`, issuer, keyId, purpose, audience, issuedAt
and expiresAt (Unix seconds). Bounds are inclusive at issuance, exclusive at
expiration; future issuance and inverted intervals fail. Purposes:

- `public-profile`: signed public projection and exact resource.
- `automation-grant`: grantId, delegateKey (raw Ed25519 public key), allowed
  actions, exact resource, and revocationRef. No root key is given to an agent.
- `action-request`: grantId, action, resource and verifier-issued nonce, signed
  by the delegate. Request lifetime must be contained in the grant lifetime.

The only implemented action is `profile.public.read`. The verifier returns the
owner-signed profile, not arbitrary caller-supplied data. It checks current
issuer key enrollment, all signatures, purpose/audience, time, grant revocation,
delegate possession, action and exact resource, matching signed profile, and
an unused challenge. Challenges expire after 60 seconds and are consumed after
all other checks. Reusable grants do not themselves become one-time tokens.

The demo creates a five-minute delegate grant on explicit user action, performs
one public read and proves replay rejection. Its registry is in memory for that
demonstration only. Key retirement and grant revocation work at that boundary and
are tested. Restart loses registry/replay state. A production verifier needs
authenticated enrollment, durable revocation and atomic nonce consumption
across concurrent requests/processes. Clock trust is also a server concern.

Rotation retains the identity ID while changing key ID/public key, retires the
old binding and invalidates dependent old grants/proofs. Tests exercise this
registry behavior. Rotation/recovery UI and a recovery authority are unimplemented;
`IdentityLifecycle` is an interface only. Losing browser/device storage currently
loses the identity. Do not claim account recovery exists.

## Key implementation and assurance

Resolved libraries: cryptography 2.9.0, cryptography_flutter 2.3.4,
flutter_secure_storage 10.3.4 (versions constrained by this Flutter SDK).
Ed25519 is implemented by the library, with supported native/browser delegation
and library fallback. No custom cryptographic primitive was implemented.

The current key adapter uses an **exportable software seed**, stored only through
FlutterSecureStorage. It never enters ordinary profile preferences, URLs,
QR payloads, logs or public proof data. There is no insecure storage fallback.
Concurrent initialization in one store instance shares a future. Cross-tab
initialization locking is not implemented; do not enroll one browser profile
concurrently from multiple tabs before its first key is stored.

Apple uses Keychain; Android uses the plugin's encrypted secure-storage path.
Android backups are disabled to avoid restoring ciphertext without its wrapping
key. This does not make the signing key non-exportable or hardware-bound.
Ed25519 permits the same wire protocol on all targets; the tradeoff is deferring
platform-specific hardware signers/algorithm negotiation. Prefer a reviewed
non-exportable hardware adapter for production. The maintained package was
researched, but an independent audit of this exact resolved package/version was
not established. The handoff's audited-library/hardware assurance gate therefore
remains open. No audit or production security certification is claimed.

Browser secure storage uses experimental origin-bound WebCrypto encryption over
local storage. Same-origin scripts/XSS can exercise or access the key; it is not
equivalent to native secure hardware. Use localhost/HTTPS. A production host must
add appropriate CSP/security headers and an enrollment/revocation service.

References: [cryptography](https://pub.dev/packages/cryptography),
[native algorithm support](https://pub.dev/packages/cryptography_flutter),
[secure storage](https://pub.dev/packages/flutter_secure_storage).

## Flow OS reuse and Longfellow-ZK

Jay confirmed future Flow OS use in this session. Inspection of the local
Flow OS `components/settings/identity-section.tsx` found its own explicit
prototype notice: presentation persists locally; keys/wallet/NFC are display
states. This work does not silently convert those states into enrollment.

Reuse the wire contract, verification policy and public test fixtures across
Dart and TypeScript/backend implementations. Do not share root private keys
between Steel and Flow OS. An authenticated linking service should bind a Steel
identity to a Flow OS actor/account, while organization membership and roles
remain organization authority. Use distinct audiences such as
`steel:personal:<service>` and `flow-os:organization:<orgId>:<service>`, exact
resource scopes, and separate org issuers/delegate grants. Public-card visibility
does not authorize org reads or writes. Any future operational memory write
must pass Flow OS's validated `emit_diff()` boundary; no signer/secret is memory.

Public deterministic TEST vectors are generated by
`dart run tool/export_protocol_fixture.dart` and stored in
`verification/protocol-fixture.json`. Their known test keys must never be used
for real enrollment. `node DOCUMENTATION/verification/verify-interop.cjs` uses
Node/OpenSSL to independently verify Dart-generated profile, grant and action
signatures; wrong-key and tampering checks also run. This proves byte/signature
interop, not a full production Flow OS authorization adapter.

[Longfellow-ZK](https://github.com/longfellow-zk/longfellow-zk) is a separate
candidate credential-proof layer. The README describes zero-knowledge protocols
over MDOC, JWT and verifiable credentials, with independent security-review
reports linked by the project. Its C++ build requires OpenSSL/zstd/CMake and
other dependencies. The Android/iOS scripts build native arm64 targets, rather
than supplying a Flutter plugin. No production-ready web/Flutter integration
was established in this session. Nothing was vendored or executed from it.

Possible next spike: an issuer-signed test membership credential, a narrowly
specified disclosure/claim, a fresh audience-bound verifier challenge, then a
native proof/verifier adapter and mobile performance measurements. Flow OS can
consume the verified claim through the same adapter boundary while retaining
its own org authorization. A ZK proof does not itself confer agent permission,
create an issuer or provide key recovery. No ZK capability is claimed here.

## Verification artifacts and limits

`verification/reference.html` is a local reference copy with analytics, form
scripts and other original behavior removed. It maps the missing portrait locally
and forces the profile visible. It preserves the original profile markup/styles;
the source website was not changed. The reference still loads Tailwind/Lucide
and Google Fonts from their CDNs for screenshot capture only.

Screenshot scripts and images live under `verification/`. The actual Flutter
app and HTML were rendered in Edge at matched card width, with 390px and 320px
phone checks. See the browser results and images for final behavior evidence.
Native mobile paths cannot be proven here: only Edge and Windows were detected,
and no Android emulator source was installed. No iOS/Android hardware key,
native contacts import/share-sheet or actual NFC success is claimed.

Production host, issued membership/legal identity checks, registry backend,
cross-device revocation, hardware key assurance, recovery and Longfellow adapters
remain external milestones. Existing unrelated logo/NFC worktree changes were
preserved. No public launch, purchases or third-party messages were performed.
