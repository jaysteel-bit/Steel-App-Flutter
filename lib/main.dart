// main.dart
// Steel by Exo — Flutter App Entry Point
//
// Steel is a privacy-first NFC tap-to-share social ecosystem.
// This Flutter version targets: iOS + Android + Web PWA.
//
// Architecture:
//   - State Management: Riverpod (ChangeNotifierProvider + StateProvider)
//   - Theme: Custom dark theme matching steel.html (emerald + glassmorphism)
//   - Services: NFCService, SMSVerificationService, ProfileService, AuthService
//   - Navigation: Onboarding → Home (NFC Tap + Profile tabs)
//
// To run:
//   flutter run -d chrome    (Web PWA — non-member fallback)
//   flutter run -d android   (Android with NFC)
//   flutter run -d ios       (iOS with NFC)
//
// Simulate mode is enabled by default for development.
// Toggle it off in Settings to use real NFC hardware.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/steel_theme.dart';
import 'providers/providers.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/home/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar to match Steel's dark aesthetic
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SteelColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    // Riverpod scope — provides all services to the widget tree
    const ProviderScope(
      child: SteelApp(),
    ),
  );
}

/// Root widget for the Steel app.
class SteelApp extends ConsumerStatefulWidget {
  const SteelApp({super.key});

  @override
  ConsumerState<SteelApp> createState() => _SteelAppState();
}

class _SteelAppState extends ConsumerState<SteelApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize services on app startup.
  Future<void> _initializeApp() async {
    final authService = ref.read(authServiceProvider);
    await authService.initialize();

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steel by Exo',
      debugShowCheckedModeBanner: false,

      // Steel's custom dark theme — matches steel.html design system
      theme: steelThemeData(),

      home: _isInitialized ? _buildHome() : _buildSplash(),
    );
  }

  /// Determine which screen to show based on auth state.
  Widget _buildHome() {
    final authService = ref.watch(authServiceProvider);

    // Show onboarding if user hasn't completed it yet
    if (!authService.hasCompletedOnboarding) {
      return const OnboardingView();
    }

    // Show main app
    return const HomeView();
  }

  /// Simple splash screen while services initialize.
  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: SteelColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Steel logo placeholder
            Text(
              'STEEL',
              style: SteelFonts.sans(
                size: 32,
                weight: FontWeight.w500,
                color: SteelColors.accent,
              ).copyWith(letterSpacing: 8),
            ),
            const SizedBox(height: SteelSpacing.lg),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SteelColors.accent.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
