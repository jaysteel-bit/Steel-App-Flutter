// auth_service.dart
// Steel by Exo — Authentication Service (Flutter)
//
// Ported from AuthService.swift (iOS version).
// Handles user authentication and session management.
//
// For MVP: Uses local state + shared_preferences.
// Production: Will integrate with Supabase Auth (email/phone + social logins).
//
// Auth flow:
//   1. New user → Onboarding → Sign up (email/phone)
//   2. Existing user → Auto-login from saved session
//   3. Guest → Limited access (can view web profiles but not share)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/steel_profile.dart';

/// Authentication state.
enum AuthState {
  unknown,        // Haven't checked yet
  unauthenticated, // No saved session
  authenticated,   // Logged in
}

/// Service for managing user authentication and session.
class AuthService extends ChangeNotifier {

  AuthState _state = AuthState.unknown;
  SteelProfile? _currentUser;
  bool _hasCompletedOnboarding = false;

  AuthState get state => _state;
  SteelProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// Initialize the auth service — check for saved session.
  /// Call this at app startup.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;
    final savedUserId = prefs.getString('user_id');

    if (savedUserId != null) {
      // In production: Validate session token with backend
      // For MVP: Just restore mock user
      _currentUser = SteelProfile.mock;
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  /// Sign in (stub — production will use Supabase Auth).
  Future<bool> signIn({required String email, required String password}) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network

      // ── STUB: Always succeed with mock user ──
      _currentUser = SteelProfile.mock;
      _state = AuthState.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _currentUser!.id);

      notifyListeners();
      return true;

      // ── PRODUCTION ──
      // final response = await supabase.auth.signInWithPassword(
      //   email: email, password: password,
      // );
      // if (response.user != null) { ... }

    } catch (e) {
      debugPrint('Sign in failed: $e');
      return false;
    }
  }

  /// Sign out — clear session.
  Future<void> signOut() async {
    _currentUser = null;
    _state = AuthState.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    notifyListeners();
  }

  /// Mark onboarding as complete.
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    notifyListeners();
  }
}
