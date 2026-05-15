import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppProvider app) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_isRegister) {
      await app.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      final success = await app.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted || success) return;
      // EMAIL_NOT_VERIFIED is shown inline — don't also show a snackbar
      if (app.authErrorCode != 'EMAIL_NOT_VERIFIED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(app.authError ?? 'Authentication failed.')),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _formKey.currentState?.reset();
    });
  }

  InputDecoration _glassInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: GlassColors.textMuted),
      prefixIcon: Icon(icon, color: GlassColors.textMuted, size: 20),
      filled: true,
      fillColor: GlassColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GlassColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GlassColors.negative),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GlassColors.negative),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    // Show verify-email screen after registration OR after login with unverified account
    if (app.pendingVerificationEmail != null) {
      return _VerifyEmailView(
        email: app.pendingVerificationEmail!,
        onResend: () => app.resendVerification(app.pendingVerificationEmail!),
        onBack: () => app.clearPendingVerification(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: GlassColors.bgGradient),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: GlassColors.surfaceHeavy,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: GlassColors.border),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isRegister ? 'Create account' : 'Welcome back',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: GlassColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegister
                            ? 'Start splitting expenses with your groups.'
                            : 'Sign in to continue managing your balances.',
                        style: const TextStyle(
                          color: GlassColors.textMuted,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Glass form card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: GlassColors.surfaceHeavy,
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: GlassColors.border),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (_isRegister) ...[
                                    TextFormField(
                                      controller: _nameController,
                                      textInputAction:
                                          TextInputAction.next,
                                      style: const TextStyle(
                                          color: GlassColors.text),
                                      decoration: _glassInput(
                                          'Full name',
                                          Icons.person_outline_rounded),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Enter your name.'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(
                                        color: GlassColors.text),
                                    decoration: _glassInput(
                                        'Email', Icons.email_outlined),
                                    validator: (v) {
                                      final e = v?.trim() ?? '';
                                      if (!e.contains('@') ||
                                          e.startsWith('@') ||
                                          e.endsWith('@')) {
                                        return 'Enter a valid email.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        _submit(app),
                                    style: const TextStyle(
                                        color: GlassColors.text),
                                    decoration: _glassInput(
                                            'Password',
                                            Icons.lock_outline_rounded)
                                        .copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: GlassColors.textMuted,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                            ? 'Use at least 6 characters.'
                                            : null,
                                  ),
                                  if (app.authError != null) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      app.authError!,
                                      style: const TextStyle(
                                        color: GlassColors.negative,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (app.authErrorCode == 'EMAIL_NOT_VERIFIED') ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => app.resendVerification(
                                            _emailController.text.trim()),
                                        child: const Text(
                                          'Resend verification email →',
                                          style: TextStyle(
                                            color: Color(0xFF9B7FD4),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 24),
                                  Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF764BA2),
                                          Color(0xFF667EEA)
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: app.authLoading
                                          ? null
                                          : () => _submit(app),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: app.authLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isRegister
                                                  ? 'Create account'
                                                  : 'Sign in',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _isRegister
                                ? 'Already have an account?'
                                : 'New to SplitEase?',
                            style: const TextStyle(
                                color: GlassColors.textMuted),
                          ),
                          TextButton(
                            onPressed:
                                app.authLoading ? null : _toggleMode,
                            child: Text(
                              _isRegister ? 'Sign in' : 'Create account',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyEmailView extends StatefulWidget {
  final String email;
  final VoidCallback onResend;
  final VoidCallback onBack;
  const _VerifyEmailView({
    required this.email,
    required this.onResend,
    required this.onBack,
  });

  @override
  State<_VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<_VerifyEmailView> {
  bool _resent = false;
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    widget.onResend();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _resent = true; _resending = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: GlassColors.bgGradient),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: GlassColors.surfaceHeavy,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: GlassColors.border),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF764BA2).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: const Color(0xFF764BA2).withValues(alpha: 0.4)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.mark_email_unread_rounded,
                                      color: Color(0xFF9B7FD4), size: 34),
                                ),
                                const SizedBox(height: 24),
                                const Text('Check your inbox',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: GlassColors.text)),
                                const SizedBox(height: 10),
                                Text(
                                  'We sent a verification link to',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: GlassColors.textMuted, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onLongPress: () {
                                    Clipboard.setData(ClipboardData(text: widget.email));
                                  },
                                  child: Text(
                                    widget.email,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap the link in the email, then come back and sign in.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: GlassColors.textMuted, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 28),
                                GestureDetector(
                                  onTap: (_resending || _resent) ? null : _resend,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: (_resending || _resent)
                                          ? null
                                          : const LinearGradient(
                                              colors: [Color(0xFF764BA2), Color(0xFF667EEA)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      color: (_resending || _resent)
                                          ? GlassColors.surface
                                          : null,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: _resending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white))
                                        : Text(
                                            _resent ? 'Email sent!' : 'Resend email',
                                            style: TextStyle(
                                              color: _resent
                                                  ? GlassColors.positive
                                                  : Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: widget.onBack,
                        child: const Text('Back to sign in',
                            style: TextStyle(color: GlassColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
