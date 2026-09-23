import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emarket_logo.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_service.dart';
import '../domain/user_profile.dart';

enum AuthMode { signIn, signUp }

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    this.returnOnSuccess = false,
    this.showVisitorOption = true,
  });

  final bool returnOnSuccess;
  final bool showVisitorOption;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _whatsappController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;
  bool _hidePassword = true;
  bool _loading = false;
  UserRole _role = UserRole.client;

  bool get _isSignIn => _mode == AuthMode.signIn;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.danger : AppColors.ink,
        ),
      );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      if (_isSignIn) {
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.register(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          role: _role,
          whatsappNumber: _whatsappController.text,
        );
      }

      if (!mounted) return;

      if (widget.returnOnSuccess) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthFailure catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    try {
      await _authService.sendPasswordReset(_emailController.text);
      _showMessage(
        'Password reset email sent. Check your inbox.',
        error: false,
      );
    } on AuthFailure catch (error) {
      _showMessage(error.message);
    }
  }

  void _continueAsVisitor() {
    Navigator.of(context).push(
      smoothRoute(const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: _Header(isSignIn: _isSignIn),
            ),
            Expanded(
              flex: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _ModeSwitch(
                          mode: _mode,
                          enabled: !_loading,
                          onChanged: (mode) {
                            setState(() => _mode = mode);
                            _formKey.currentState?.reset();
                          },
                        ),
                        const SizedBox(height: 22),
                        PageTransitionSwitcher(
                          duration: const Duration(milliseconds: 360),
                          transitionBuilder: (
                            child,
                            primaryAnimation,
                            secondaryAnimation,
                          ) {
                            return SharedAxisTransition(
                              animation: primaryAnimation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType:
                                  SharedAxisTransitionType.horizontal,
                              fillColor: Colors.transparent,
                              child: child,
                            );
                          },
                          child: _isSignIn
                              ? _SignInFields(
                                  key: const ValueKey('signin'),
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  hidePassword: _hidePassword,
                                  enabled: !_loading,
                                  onTogglePassword: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  onForgotPassword: _resetPassword,
                                )
                              : _SignUpFields(
                                  key: const ValueKey('signup'),
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  phoneController: _phoneController,
                                  passwordController: _passwordController,
                                  whatsappController: _whatsappController,
                                  hidePassword: _hidePassword,
                                  role: _role,
                                  enabled: !_loading,
                                  onTogglePassword: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  onRoleChanged: (role) => setState(
                                    () => _role = role,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _loading
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignIn
                                        ? 'Sign in'
                                        : 'Create account',
                                    key: const ValueKey('label'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        if (widget.showVisitorOption) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _loading ? null : _continueAsVisitor,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Continue as visitor'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Visitors can browse now. Buying requires authentication.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isSignIn});

  final bool isSignIn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -80,
          top: -90,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const EMarketLogo(
                size: 42,
                showWordmark: true,
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isSignIn ? 'Welcome back.' : 'Join e-market.',
                  key: ValueKey(isSignIn),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isSignIn
                      ? 'Pick up where you left off — your market is waiting.'
                      : 'Create your profile as a client or seller.',
                  key: ValueKey('subtitle-$isSignIn'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final AuthMode mode;
  final bool enabled;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _tab('Sign In', AuthMode.signIn),
          _tab('Sign Up', AuthMode.signUp),
        ],
      ),
    );
  }

  Widget _tab(String label, AuthMode value) {
    final selected = value == mode;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: TextButton(
          onPressed: enabled ? () => onChanged(value) : null,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInFields extends StatelessWidget {
  const _SignInFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.hidePassword,
    required this.enabled,
    required this.onTogglePassword,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool hidePassword;
  final bool enabled;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          validator: _validateEmail,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: passwordController,
          enabled: enabled,
          obscureText: hidePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: enabled ? onTogglePassword : null,
              icon: Icon(
                hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Firebase keeps your mobile session secure',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: enabled ? onForgotPassword : null,
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignUpFields extends StatelessWidget {
  const _SignUpFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.whatsappController,
    required this.hidePassword,
    required this.role,
    required this.enabled,
    required this.onTogglePassword,
    required this.onRoleChanged,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController whatsappController;
  final bool hidePassword;
  final UserRole role;
  final bool enabled;
  final VoidCallback onTogglePassword;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (value) {
            if ((value ?? '').trim().length < 2) {
              return 'Enter your full name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: emailController,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          validator: _validateEmail,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: phoneController,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            if ((value ?? '').trim().length < 6) {
              return 'Enter a valid phone number.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: passwordController,
          enabled: enabled,
          obscureText: hidePassword,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: enabled ? onTogglePassword : null,
              icon: Icon(
                hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<UserRole>(
          initialValue: role,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: UserRole.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value.label),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onRoleChanged(value);
                }
              : null,
        ),
        if (role == UserRole.seller) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: whatsappController,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'WhatsApp number (e.g. +257...)',
              prefixIcon: Icon(Icons.chat_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().length < 7) {
                return 'Seller WhatsApp number is required.';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

String? _validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Email is required.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password is required.';
  if (password.length < 6) return 'Use at least 6 characters.';
  return null;
}
