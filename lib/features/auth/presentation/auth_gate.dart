import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

        return StreamBuilder<UserProfile?>(
          stream: _profiles.watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _ProfileError(
                onSignOut: _authService.signOut,
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting ||
                profileSnapshot.data == null) {
              return const _GateLoading(message: 'Finishing your profile...');
            }

            return HomePage(profile: profileSnapshot.data!);
          },
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
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
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
