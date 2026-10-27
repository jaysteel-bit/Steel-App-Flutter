import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../identity/key_store.dart';
import '../identity/protocol.dart';
import '../theme/steel_theme.dart';
import '../views/components/metallic_text.dart';
import 'profile.dart';

class DigitalHome extends StatefulWidget {
  const DigitalHome({super.key});
  @override
  State<DigitalHome> createState() => _DigitalHomeState();
}

class _DigitalHomeState extends State<DigitalHome> {
  final repository = ProfileRepository();
  final keyStore = SecureIdentityKeyStore();
  DigitalProfile profile = const DigitalProfile();
  bool ready = false, revealed = true, busy = false;
  late final bool visitor;
  @override
  void initState() {
    super.initState();
    visitor = Uri.base.fragment.startsWith('/public');
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await repository.load();
      if (mounted) {
        setState(() {
          profile = p;
          ready = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => ready = true);
        message(
          'Saved profile could not be loaded. Showing reference fixture.',
        );
      }
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> open(Uri uri) async {
    try {
      if (!await launchUrl(uri)) message('Could not open this link.');
    } catch (_) {
      message('No app is available for this link.');
    }
  }

  Future<void> exportContact() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(utf8.encode(profile.vCard), mimeType: 'text/vcard'),
          ],
          fileNameOverrides: ['steel-contact.vcf'],
          sharePositionOrigin: const Rect.fromLTWH(20, 20, 200, 50),
          downloadFallbackEnabled: true,
        ),
      );
    } catch (_) {
      message('Contact export unavailable on this platform.');
    }
  }

  Future<void> shareProfile() async {
    // Share an explicit public projection; never leak the owner record.
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${profile.name}\n${profile.headline}\n${jsonEncode(profile.publicData)}',
          sharePositionOrigin: const Rect.fromLTWH(20, 20, 200, 50),
        ),
      );
    } catch (_) {
      await Clipboard.setData(
        ClipboardData(text: jsonEncode(profile.publicData)),
      );
      message('Public profile copied.');
    }
  }

  Future<void> security() async {
    setState(() => busy = true);
    try {
      final signer = await keyStore.loadOrCreate();
      final result = await automationDemo(signer, profile.publicData);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Identity & permissions'),
          content: SingleChildScrollView(
            child: Text(
              '${signer.identityId}\n${signer.keyId}\n\n$result\n\n'
              'Self-enrolled key control only. No Exo membership or legal identity verification.\n\n'
              '${kIsWeb ? 'Browser: origin-bound experimental encrypted storage. Same-origin scripts can access the key.' : 'Exportable Ed25519 key stored using platform secure storage. Hardware isolation is not claimed.'}\n\n'
              'Demo delegate expires in 5 minutes and can only read this public profile. '
              'Registry and replay protection exist only for this demonstration. '
              'Cross-device revocation, account enrollment, rotation and recovery require a backend.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      message(
        'Secure identity unavailable. No insecure storage fallback was used.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit() async {
    final updated = await Navigator.push<DigitalProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditor(profile: profile, repository: repository),
      ),
    );
    if (updated != null && mounted) setState(() => profile = updated);
  }

  void waitlist() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Steel by Exo'),
      content: const Text(
        'Invitation requests are not connected in this local preview. No information is collected.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 600;
          final card = SteelDigitalCard(
            profile: profile,
            onContact: exportContact,
            onWaitlist: waitlist,
            onInstagram: () => profile.instagram.isEmpty
                ? message('Instagram is not configured.')
                : open(
                    Uri.https('www.instagram.com', '/${profile.instagram}/'),
                  ),
            onLinkedin: () => profile.linkedin.isEmpty
                ? message('LinkedIn is not configured.')
                : open(Uri.parse(profile.linkedin)),
            onPhone: () => !profile.publishPhone || profile.phone.isEmpty
                ? message('No public phone number shared.')
                : open(Uri(scheme: 'tel', path: profile.phone)),
          );
          final content = AnimatedSwitcher(
            duration: const Duration(milliseconds: 650),
            child: revealed
                ? Padding(
                    key: const ValueKey('revealed'),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: card,
                  )
                : Column(
                    key: const ValueKey('locked'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 192,
                        height: 192,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xAA10B981),
                              Color(0x2210B981),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.blur_on,
                          size: 112,
                          color: SteelColors.accent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Tap to Connect',
                        style: SteelFonts.serif(
                          size: 30,
                          style: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preview the public profile',
                        style: SteelFonts.caption,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() => revealed = true),
                        child: const Text('Reveal Profile'),
                      ),
                    ],
                  ),
          );
          return Stack(
            children: [
              Positioned(
                top: -180,
                left: -180,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0x1210B981), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text(
                          'STEEL BY EXO',
                          style: SteelFonts.sans(
                            size: 12,
                            color: SteelColors.textMuted,
                          ).copyWith(letterSpacing: 3.6),
                        ),
                        const SizedBox(height: 20),
                        if (desktop) ...[
                          Text.rich(
                            TextSpan(
                              text: 'Access ',
                              children: [
                                TextSpan(
                                  text: 'Redefined.',
                                  style: SteelFonts.serif(
                                    size: 54,
                                    style: FontStyle.italic,
                                    color: SteelColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            style: SteelFonts.serif(size: 54),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap. Verify. Connect — with absolute control.',
                            style: SteelFonts.sans(
                              size: 18,
                              color: SteelColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                        if (!ready)
                          const CircularProgressIndicator()
                        else
                          Container(
                            width: 384,
                            constraints: desktop
                                ? const BoxConstraints(minHeight: 700)
                                : null,
                            padding: EdgeInsets.symmetric(
                              vertical: desktop ? 32 : 24,
                            ),
                            decoration: desktop
                                ? BoxDecoration(
                                    color: SteelColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: SteelColors.glassBorder,
                                    ),
                                  )
                                : null,
                            child: content,
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => revealed = !revealed),
                              child: Text(
                                revealed ? 'Lock preview' : 'Reveal preview',
                              ),
                            ),
                            if (!visitor) ...[
                              TextButton(
                                onPressed: edit,
                                child: const Text('Edit profile'),
                              ),
                              TextButton(
                                onPressed: shareProfile,
                                child: const Text('Share public card'),
                              ),
                              TextButton(
                                onPressed: busy ? null : security,
                                child: Text(
                                  busy
                                      ? 'Verifying…'
                                      : 'Identity & permissions',
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => Scaffold(
                                      appBar: AppBar(
                                        title: const Text('Public preview'),
                                      ),
                                      body: Center(
                                        child: SingleChildScrollView(
                                          child: SizedBox(
                                            width: 384,
                                            child: Padding(
                                              padding: const EdgeInsets.all(32),
                                              child: card,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                child: const Text('Guest preview'),
                              ),
                            ],
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Text(
                            visitor
                                ? 'Local public preview · this browser’s saved profile'
                                : 'Reference fixture · local preview · no membership issued',
                            textAlign: TextAlign.center,
                            style: SteelFonts.sans(
                              size: 11,
                              color: SteelColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class SteelDigitalCard extends StatelessWidget {
  final DigitalProfile profile;
  final VoidCallback onContact, onWaitlist, onInstagram, onLinkedin, onPhone;
  const SteelDigitalCard({
    super.key,
    required this.profile,
    required this.onContact,
    required this.onWaitlist,
    required this.onInstagram,
    required this.onLinkedin,
    required this.onPhone,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: SteelColors.glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SteelColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 4,
                  color: SteelColors.accent.withValues(alpha: .5),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/alexa-pfp.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            MetallicText(
              profile.name,
              style: SteelFonts.cardName.copyWith(height: 40 / 36),
            ),
            const SizedBox(height: 24),
            Text(
              profile.headline,
              textAlign: TextAlign.center,
              style: SteelFonts.sans(
                size: 14,
                color: SteelColors.textMuted,
              ).copyWith(height: 20 / 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: SteelColors.accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'STEEL MEMBER',
                style: SteelFonts.sans(
                  size: 12,
                  color: SteelColors.accent,
                ).copyWith(height: 16 / 12),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _social(
                  'instagram',
                  profile.instagram.isEmpty
                      ? 'Instagram'
                      : '@${profile.instagram}',
                  onInstagram,
                ),
                const SizedBox(width: 24),
                _social('linkedin', 'LinkedIn', onLinkedin),
                const SizedBox(width: 24),
                _social('phone', 'Contact', onPhone),
              ],
            ),
            const SizedBox(height: 24),
            _button('Add to Contacts', onContact, true),
            const SizedBox(height: 16),
            _button('Join the Waitlist', onWaitlist, false),
          ],
        ),
      ),
    ),
  );
  Widget _social(String icon, String text, VoidCallback onTap) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/$icon.svg',
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: SteelFonts.sans(size: 12).copyWith(height: 16 / 12),
          ),
        ],
      ),
    ),
  );
  Widget _button(String text, VoidCallback onTap, bool primary) => SizedBox(
    width: double.infinity,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: primary
            ? SteelColors.accent
            : Colors.white.withValues(alpha: .1),
        foregroundColor: primary ? Colors.black : SteelColors.text,
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(0, 48),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: SteelFonts.sans(size: 16, weight: FontWeight.w500),
      ),
      onPressed: onTap,
      child: Text(text),
    ),
  );
}

class ProfileEditor extends StatefulWidget {
  final DigitalProfile profile;
  final ProfileRepository repository;
  const ProfileEditor({
    super.key,
    required this.profile,
    required this.repository,
  });
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  late bool publishPhone;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    fields = [
      p.name,
      p.headline,
      p.instagram,
      p.linkedin,
      p.phone,
      p.privateEmail,
    ].map((s) => TextEditingController(text: s)).toList();
    publishPhone = p.publishPhone;
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    final p = DigitalProfile(
      name: fields[0].text.trim(),
      headline: fields[1].text.trim(),
      instagram: fields[2].text.trim(),
      linkedin: fields[3].text.trim(),
      phone: fields[4].text.trim(),
      privateEmail: fields[5].text.trim(),
      publishPhone: publishPhone,
    );
    try {
      await widget.repository.save(p);
      if (mounted) Navigator.pop(context, p);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Could not save. Please try again.';
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your profile')),
    body: Center(
      child: SizedBox(
        width: 480,
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Choose what visitors see. Private email is never included in the public card or vCard.',
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: fields[i],
                    maxLength: i == 0 ? 60 : 160,
                    decoration: InputDecoration(
                      labelText: [
                        'Name',
                        'Headline',
                        'Instagram username (no @)',
                        'LinkedIn HTTPS URL',
                        'Phone',
                        'Private email',
                      ][i],
                      fillColor: SteelColors.surfaceAlt,
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (i == 0 && v.isEmpty) return 'Enter a name';
                      if (i == 2 &&
                          v.isNotEmpty &&
                          !RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(v)) {
                        return 'Enter a username without @';
                      }
                      if (i == 3 && v.isNotEmpty) {
                        final u = Uri.tryParse(v);
                        if (u == null ||
                            u.scheme != 'https' ||
                            ![
                              'linkedin.com',
                              'www.linkedin.com',
                            ].contains(u.host) ||
                            u.userInfo.isNotEmpty) {
                          return 'Use an https://www.linkedin.com/ URL';
                        }
                      }
                      if (i == 4 &&
                          v.isNotEmpty &&
                          !RegExp(r'^\+?[0-9 ()-]{3,32}$').hasMatch(v)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share phone publicly'),
                value: publishPhone,
                onChanged: (v) => setState(() => publishPhone = v),
              ),
              if (error != null) Text(error!),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving…' : 'Save profile'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
