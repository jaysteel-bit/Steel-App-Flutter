// home_view.dart
// Steel by Exo — Home / Main Navigation
//
// The main app shell after onboarding. Contains:
//   - NFC Tap screen (default tab — the core experience)
//   - Profile/Settings tab
//   - Connections tab (future)
//
// Wrapped in PlatformShell so:
//   - Web: Shows phone mockup frame with Steel branding outside
//   - Mobile: Full-screen native layout
//
// Uses a minimal bottom nav with Steel's dark aesthetic.

import 'package:flutter/material.dart';
import '../../theme/steel_theme.dart';
import '../components/platform_shell.dart';
import '../components/steel_logo.dart';
import '../nfc/nfc_tap_view.dart';
import '../profile/profile_settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final _pages = const [
    NFCTapView(),          // Tab 0: NFC tap-to-share (core experience)
    ProfileSettingsView(), // Tab 1: Profile & settings
  ];

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      showLogo: true,
      child: Scaffold(
        backgroundColor: SteelColors.background,
        body: Stack(
          children: [
            // Page content
            _pages[_currentIndex],

            // Steel logo — top left (inside the phone frame on web)
            const Positioned(
              top: 50,
              left: 16,
              child: SteelLogo(width: 80, opacity: 0.7),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: SteelColors.surface,
            border: Border(
              top: BorderSide(color: SteelColors.glassBorder),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.nfc,
                    label: 'Connect',
                    isActive: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    isActive: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? SteelColors.accent : SteelColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: SteelFonts.captionSmall.copyWith(
                color: isActive ? SteelColors.accent : SteelColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
