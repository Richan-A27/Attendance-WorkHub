import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkOfflineSession();
  }

  Future<void> _checkOfflineSession() async {
    final authService = ref.read(authServiceProvider);
    final hasSession = await authService.attemptOfflineLogin();
    if (hasSession && mounted) {
      context.go('/');
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compactHero = ResponsiveLayout.isShortHeight(context);

    return Scaffold(
      body: AppView(
        padding: EdgeInsets.fromLTRB(
          ResponsiveLayout.pageHorizontalPadding(context),
          24,
          ResponsiveLayout.pageHorizontalPadding(context),
          24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ResponsiveLayout(
              mobile: _LoginCard(
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                onLogin: _login,
                onGoogleLogin: _loginWithGoogle,
              ),
              tablet: _LoginCard(
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                onLogin: _login,
                onGoogleLogin: _loginWithGoogle,
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LoginShowcase(isCompact: compactHero)),
                  const SizedBox(width: 28),
                  SizedBox(
                    width: 430,
                    child: _LoginCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: _isLoading,
                      onLogin: _login,
                      onGoogleLogin: _loginWithGoogle,
                    ),
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

class _LoginShowcase extends StatelessWidget {
  final bool isCompact;

  const _LoginShowcase({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      gradient: const LinearGradient(
        colors: [AppTheme.darkGreenSidebar, Color(0xFF234534)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 6 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 58 : 72,
              height: isCompact ? 58 : 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGold, Color(0xFFF0D67F)],
                ),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: AppTheme.darkGreenSidebar,
                size: 34,
              ),
            ),
            SizedBox(height: isCompact ? 18 : 28),
            Text(
              'ISRAVEL WorkHub',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: isCompact ? 32 : 44,
                  ),
            ),
            SizedBox(height: isCompact ? 10 : 14),
            Text(
              'Enterprise workforce intelligence for attendance, payroll, reporting, and operations.',
              style: TextStyle(
                color: const Color(0xFFD2E3D8),
                fontSize: isCompact ? 15 : 17,
                height: 1.55,
              ),
            ),
            SizedBox(height: isCompact ? 18 : 30),
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppStatusBadge(
                  label: 'Live attendance visibility',
                  color: AppTheme.accentGold,
                  icon: Icons.visibility_rounded,
                ),
                AppStatusBadge(
                  label: 'Payroll-ready operations',
                  color: Color(0xFF8FE0A9),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                AppStatusBadge(
                  label: 'Device sync monitoring',
                  color: Color(0xFFA9D0FF),
                  icon: Icons.sync_rounded,
                ),
              ],
            ),
            SizedBox(height: isCompact ? 18 : 26),
            const Row(
              children: [
                Expanded(
                  child: _ShowcaseMetric(
                    label: 'Platform posture',
                    value: 'Premium',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _ShowcaseMetric(
                    label: 'Experience focus',
                    value: 'Admin-first',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
    required this.onGoogleLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Administrator access',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to continue managing attendance operations, payroll cycles, and workforce reporting.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Work email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign in to WorkHub'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: isLoading ? null : onGoogleLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Secure admin workspace'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: _ShowcaseMetric(
                    label: 'Brand',
                    value: 'ISRAVEL',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: _ShowcaseMetric(
                    label: 'Mode',
                    value: 'Enterprise',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowcaseMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ShowcaseMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
