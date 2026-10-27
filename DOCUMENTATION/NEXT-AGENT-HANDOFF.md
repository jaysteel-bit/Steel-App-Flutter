# Steel digital card, profile and cryptographic identity — next-agent prompt

Copy everything below into the next coding agent's chat, or ask it to read this file and execute it.

---

You are taking over Steel by Exo. Start implementing the digital Steel card and profile in Flutter now. The work includes cryptographic identity for security and automation. Do not stop after another strategy document or plan. Inspect the current work, implement the requested slice, run it, and verify the result visually and functionally.

## Authoritative requirements

- Workspace: `C:\Users\viole\Desktop\steel-flutter`.
- Keep Flutter for iOS, Android and a usable web preview. The old implementation is replaceable; reuse only what helps achieve the requested result.
- Exact visual reference: `C:\Users\viole\Desktop\WEBSITES\steelaccess-html\steel.html`. This newer user-specified path supersedes the earlier reference location. Read its source and render it. The profile inside `#profile`, its containing composition and the locked/reveal states are the design authority. Existing Flutter comments claiming a match are not evidence.
- Digital card/profile immediately, physical card later. Keep real NFC support as a separate hardware delivery lane. Phone-to-phone tap has not been wired or proven. Do not make it a dependency for showing or using the digital profile, and do not call a simulation real NFC. The current immediate digital-build instruction governs sequencing where older notes say hardware must precede UI.
- Include actual cryptographic identity technology, not merely a random identifier, badge, QR code, PIN animation or hash of profile text.
- Work autonomously on routine reversible implementation choices. Preserve unrelated user changes. Ask only for an actual missing decision or credential that prevents dependent work; continue independent work where possible.

## Business and product context to retain

Steel is Exo Enterprise's consumer-facing premium identity/access/lifestyle brand. The card represents the member; their assistant will coordinate relationships, life admin, shopping and experiences. Exo provides shared execution, integration and eventual human/vendor fulfillment services. Flow OS is Exo's flagship B2B operating product. Shared capability does not mean shared unrestricted access to personal and company data.

The intended agent experience is one personal assistant across the Flutter app and messaging, supported by specialized workers. Longer-term ideas include Photon/Spectrum messaging, agent-to-agent member coordination, shopping, merchant/payment partnerships and real-world concierge. Jay explicitly expects the commercial partnerships to be planned. Those are legitimate future architecture requirements, not tasks that must all be completed before this digital card exists.

Read the relevant Steel sub-brand context before implementation:

- `C:\Users\viole\Desktop\agent-workspace\Exo Enterprise\company-ssot\sub-brands\steel.md`
- `C:\Users\viole\Desktop\agent-workspace\Exo Enterprise\company-ssot\sub-brands\steel-product-spec.md`
- `C:\Users\viole\Desktop\agent-workspace\Exo Enterprise\company-ssot\sub-brands\steel-global.md`
- `C:\Users\viole\Desktop\agent-workspace\Exo Enterprise\EXO-MODEL-V1.5.md`
- `C:\Users\viole\Desktop\agent-workspace\NOTEPAD\Concierge-ModelV1.5-Adds.md`
- Research: `C:\Users\viole\Desktop\agent-workspace\Exo Enterprise\strategy-notes\steel-agent-app-assessment-2026-10-02.md`
- Earlier interaction ideas: `C:\Users\viole\Desktop\agent-workspace\state\tasks\steel-app-nfc-spec.md`

Honor applicable AGENTS.md instructions and workspace entry requirements. Older company launch restrictions do not cancel the current user instruction to implement this digital product slice. Do not invent approval for public launch, purchases, pricing or a complete company-model rewrite.

## Current state verified at handoff

The Flutter project exists. `pubspec.yaml` includes Riverpod, Google Fonts, shimmer, nfc_manager, shared_preferences and HTTP. Flutter was found at `C:\src\flutter\bin\flutter.bat`; verify tool versions and devices yourself.

Useful files to inspect:

- `lib/main.dart`
- `lib/theme/steel_theme.dart`
- `lib/models/steel_profile.dart`
- `lib/providers/providers.dart`
- `lib/views/home/home_view.dart`
- `lib/views/components/platform_shell.dart`
- `lib/views/components/glass_card.dart`
- `lib/views/components/metallic_text.dart`
- `lib/views/profile/profile_reveal_view.dart`
- `lib/views/profile/profile_settings_view.dart`
- `lib/services/auth_service.dart`
- `lib/services/profile_service.dart`
- `lib/services/nfc_service.dart`

Authentication and profile fetches currently use mock implementations. The old fixture uses Alexa Rivera and an unrelated remote portrait; the HTML uses Alexis Rivera. Do not preserve those discrepancies in the reference preview.

The HTML expects `assets/images/steel-assets/alexa-pfp.jpg`, which is missing from the new website folder. The original asset was verified at:

`C:\Users\viole\Desktop\Biz Folder\Exo Biz\EXO-HTML\assets\images\steel-assets\alexa-pfp.jpg`

Use that asset in a local reference preview and bundle the appropriate copy in Flutter. Do not silently replace it with a random internet portrait. Avoid modifying the source website just to repair its preview; use a local preview copy/asset mapping where appropriate.

Before touching files, recheck `git status`. At handoff there were pre-existing changes involving `NFC-Core-Apple/BuildingAnNFCTagReaderApp`, deletion of root `Steel Logo - Transparent.png`, and untracked `Steel by Exo — Flutter README.txt`, `logos/`, and `nul`. Do not reset, delete or accidentally stage those unrelated changes. No app build, screenshot comparison or runtime test was performed in this handoff session.

## Implement the visual product

Reproduce the actual HTML card, not a generic wallet, credit card or dashboard redesign. In particular:

- Background `#050505`; surface `#0a0a0a`; input surface `#1f1f1f`.
- Text `#f5f5f5`; muted text `#a3a3a3`; emerald `#10b981`.
- Glass fill white at 5%, border white at 10%, backdrop blur matching the 12px reference.
- Profile card `rounded-2xl` treatment: the HTML uses a 16px card radius, distinct from the outer phone shell. Match measured padding, gaps and proportions.
- Circular 128px portrait with emerald border, italic 36px Playfair Display name with silver/white shimmer, Inter supporting text, compact Steel Member pill.
- Three social/contact columns, using recognizable Instagram/LinkedIn/phone glyphs rather than generic camera/briefcase replacements.
- Emerald primary and translucent secondary buttons, matching the HTML labels in visitor/reference mode: Add to Contacts and Join the Waitlist.
- Subtle ambient glow, orb and reveal motion. Native mobile should not be trapped inside a second decorative phone frame. A desktop preview may use the reference composition.

Use the literal HTML fixture for visual comparison first, then bind the reusable components to profile data. A member's own view may offer edit/share controls outside the reference card. Visitors see only the intended public fields. Preserve the distinction between the owner view and public profile.

Deliver a usable digital slice: card/profile view, owner data editing with local persistence unless a real backend is already available, a guest/public preview, and functional contact/link/share behavior appropriate to the platform. Contact export should produce a real vCard; URLs must correspond to configured profile fields. If there is no deployed profile host, provide a working local preview/route and accurately state its limits instead of claiming a copied production URL is live. Do not activate the website's old analytics, lead collection or Mailchimp workflows merely to reproduce its appearance. Clearly identify demo fixtures in preview/documentation, without cluttering the card itself.

## Implement cryptographic identity and its first automation boundary

Make this an actual working signing/verifying slice, designed to extend to member-agent automation:

1. Define a stable opaque Steel identity ID, distinct from a replaceable signing key ID/public key. Document the enrollment/trust relationship. A self-generated key proves control of that key; it does not prove a legal identity or Exo-issued membership.
2. Generate an asymmetric signing key through a maintained, audited platform/library implementation. Research current Flutter/iOS/Android/web support before selecting the algorithm and storage adapter. Do not implement custom crypto. Prefer native non-exportable keys where supported; otherwise document encrypted secure-storage behavior. Never put private keys in SharedPreferences, ordinary profile JSON, logs, QR payloads or public URLs. Do not imply browser storage has the same security guarantees as native secure hardware.
3. Define a versioned, unambiguous signed profile-proof envelope with identity ID, key ID, permitted public profile data or its canonical digest, purpose/audience and validity metadata. Define canonical signing bytes. Verification must detect modified data, wrong key/purpose/audience and expiration. Keep proof serialization separate from visual presentation.
4. Define a versioned signed automation grant: issuer, delegate/agent public key, audience, allowed actions, resource scope, grant ID, issued time, expiration and revocation reference. Enforce those fields in a working verifier; bind demonstration requests to the delegate's proof of key possession. Do not treat possession of the public card as permission to act, or grant a delegate the member's private root key.
5. Distinguish reusable grants from one-time action challenges. Apply nonce/replay protection to signed action requests and validate it at the verifier. Design rotation and revocation explicitly. Durable, cross-device revocation and trusted key enrollment require an authoritative registry/backend; inspect existing services before creating one. If the first milestone uses a local verifier/registry, label that boundary honestly and do not claim production multi-user security.
6. Provide a minimal end-to-end automation demonstration using a harmless read-only operation on approved public profile data. It should succeed only for a correctly scoped, valid, signed request. No purchases, messages to third parties, financial permissions or broad account access are needed for this proof.
7. Design interfaces for key rotation/recovery without claiming unfinished recovery works. Keep personal, organizational, public-profile and agent authority distinct. An identity badge should describe only what the implemented trust model actually verifies.

Keep cryptographic implementation metadata out of the primary card layout unless it helps the user. A details/security view can explain identity, key status and granted permissions. Public proofs must not disclose private profile fields, connected accounts or secrets.

## Agent/backend architecture boundary

OpenMuse is optional acceleration, not a prerequisite for this first digital build. Research on October 2 inspected CopilotKit/openmuse commit `9ec439fbaa878197d9d44c2aa982cca55676dd68`: useful durable tasks, approvals and receipts; React Native frontend; single-owner authentication; required external CopilotKit Intelligence conversation service. Revalidate upstream if used. Do not port Steel to React Native or adopt OpenMuse's singleton owner as member authentication.

Keep profile, crypto identity, authorization and future agent transport behind clear interfaces. Later Exo outcome integration must use its validated `emit_diff()` vocabulary/write contract; do not dump raw secrets or signers into operational memory. Do not rebuild all of Flow OS or integrate every future feature in this first slice.

## Verification and completion

- Run Flutter dependency resolution, analysis, relevant existing tests, and a web build. Repair failures caused by your changes; distinguish pre-existing issues with evidence.
- Run the app. Capture the actual Flutter card and the rendered HTML reference at matched viewport/card sizes. Inspect them side by side and iterate on typography, image, icon shapes, padding, borders and geometry. Comments or a passing compiler do not prove visual fidelity.
- Exercise profile editing/persistence, visitor filtering, contact export, links, sharing, and locked/reveal behavior where implemented. Verify a narrow phone viewport and desktop preview without overflow.
- Add meaningful crypto/authorization tests: valid signature, tampering, wrong signing key, wrong delegate, purpose/audience mismatch, expired grant, unauthorized action/resource, replay, and revoked/rotated key behavior at the implemented registry boundary. Explain precisely what is and is not proven.
- Verify supported native crypto/storage paths where tooling permits. Report untested devices/platforms explicitly; a web build does not prove iOS/Android hardware storage or NFC behavior. No real NFC success claim without actual hardware evidence.
- Save screenshots, exact run instructions and a concise account of working behavior and remaining external dependencies. Open the working preview when available.

First milestone is complete when the actual Flutter app faithfully renders the specified digital card/profile, the digital interactions work, and the cryptographic identity plus scoped signing/verification demonstration work with meaningful failure-case tests. Clearly distinguish this functional milestone from production account issuance, legal identity verification, hosted public launch, hardware NFC and the future full concierge platform.

Start with repository/context inspection and a rendered HTML baseline, then implement. Do not end the turn with only a proposal or ask Jay to approve routine implementation steps already authorized by this prompt.
