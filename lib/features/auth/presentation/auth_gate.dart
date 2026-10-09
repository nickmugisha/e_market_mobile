import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/leaf_bag_loader.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_service.dart';
import '../data/user_profile_repository.dart';
import '../domain/user_profile.dart';
import 'auth_page.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthService _authService = AuthService();
  final UserProfileRepository _profiles = UserProfileRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoading(message: 'Checking your session...');
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const AuthPage();
        }

        return _ProfileGate(
          user: user,
          profiles: _profiles,
          onSignOut: _authService.signOut,
        );
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    required this.user,
    required this.profiles,
    required this.onSignOut,
  });

  final User user;
  final UserProfileRepository profiles;
  final Future<void> Function() onSignOut;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  Timer? _missingProfileTimer;
  bool _showMissingProfile = false;

  @override
  void initState() {
    super.initState();
    _startMissingProfileTimer();
  }

  @override
  void didUpdateWidget(covariant _ProfileGate oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.uid != widget.user.uid) {
      _startMissingProfileTimer();
    }
  }

  void _startMissingProfileTimer() {
    _missingProfileTimer?.cancel();

    _showMissingProfile = false;

    _missingProfileTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;

      setState(() {
        _showMissingProfile = true;
      });
    });
  }

  @override
  void dispose() {
    _missingProfileTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: widget.profiles.watchProfile(widget.user.uid),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          return _ProfileError(onSignOut: widget.onSignOut);
        }

        final profile = profileSnapshot.data;

        if (profile != null) {
          _missingProfileTimer?.cancel();

          return HomePage(profile: profile);
        }

        if (profileSnapshot.connectionState == ConnectionState.waiting ||
            !_showMissingProfile) {
          return const _GateLoading(message: 'Finishing your profile...');
        }

        return _MissingProfile(
          email: widget.user.email ?? '',
          onSignOut: widget.onSignOut,
        );
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasFor(context),
      body: Center(child: LeafBagLoader(message: message)),
    );
  }
}

class _MissingProfile extends StatelessWidget {
  const _MissingProfile({required this.email, required this.onSignOut});

  final String email;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.accent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Profile setup incomplete',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  email.isEmpty
                      ? 'Your account is signed in, but its e-market profile could not be found.'
                      : '$email is signed in, but its e-market profile could not be found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign out and try creating the account again after checking your connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async => onSignOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.accent,
                  size: 54,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Profile unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'e-market could not read your Firestore profile. Check the connection and security rules, then reopen the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton(
                  onPressed: () async => onSignOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
