import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/auth/presentation/screens/auth_brand_panel.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _keepSignedIn = true;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  bool get _emailValid => _emailRegex.hasMatch(_emailCtrl.text.trim());

  @override
  void initState() {
    super.initState();
    // Rebuild so the email field shows its valid-state checkmark live.
    _emailCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Shared form body (desktop) ───────────────────────────────────────────
  Widget _buildForm(BuildContext context, bool loading) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WELCOME BACK',
            style: PayPactTypography.label
                .copyWith(color: pt.accent, letterSpacing: 1.6)),
        const SizedBox(height: 14),
        Text("Hello, friend.\nLet's get you in.",
            style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
        const SizedBox(height: 10),
        Text(
          "Sign in with your email — we'll keep things calm.",
          style: PayPactTypography.bodyLg.copyWith(color: pt.ink2),
        ),
        const SizedBox(height: 36),
        _Label(text: 'EMAIL'),
        const SizedBox(height: 8),
        _TextField(
          controller: _emailCtrl,
          icon: Icons.mail_outline_rounded,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          suffix: _emailValid
              ? Icon(Icons.check_rounded, color: pt.positive, size: 18)
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Label(text: 'PASSWORD'),
            Text('Forgot?',
                style: PayPactTypography.bodySm
                    .copyWith(color: pt.accent, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        _TextField(
          controller: _passwordCtrl,
          icon: Icons.lock_outline_rounded,
          hint: '••••••••',
          obscure: _obscure,
          suffix: GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: pt.ink3,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => setState(() => _keepSignedIn = !_keepSignedIn),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _keepSignedIn ? pt.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: _keepSignedIn ? pt.accent : pt.borderStrong,
                      width: 1.5),
                ),
                child: _keepSignedIn
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),
              Text('Keep me signed in on this device',
                  style: PayPactTypography.bodySm.copyWith(color: pt.ink2)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PayPactButton(
          onPressed: loading
              ? null
              : () => locator<AuthCubit>().signInWithEmail(
                    _emailCtrl.text.trim(),
                    _passwordCtrl.text,
                  ),
          label: loading ? 'Signing in…' : 'Sign in to PayPact',
          variant: PayPactButtonVariant.accent,
          size: PayPactButtonSize.large,
          isFullWidth: true,
          leftIcon: Icons.arrow_forward_rounded,
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Divider(color: pt.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR',
                style: PayPactTypography.label.copyWith(color: pt.ink3)),
          ),
          Expanded(child: Divider(color: pt.border)),
        ]),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: PayPactButton(
                onPressed: loading
                    ? null
                    : () => locator<AuthCubit>().signInWithGoogle(),
                label: 'Google',
                variant: PayPactButtonVariant.secondary,
                size: PayPactButtonSize.large,
                isFullWidth: true,
                leftIcon: Icons.g_mobiledata_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PayPactButton(
                onPressed: loading
                    ? null
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Apple sign-in is coming soon.')),
                        ),
                label: 'Apple',
                variant: PayPactButtonVariant.secondary,
                size: PayPactButtonSize.large,
                isFullWidth: true,
                leftIcon: Icons.apple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text.rich(
            TextSpan(
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3),
              children: [
                const TextSpan(text: 'By signing in you agree to our '),
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                      color: pt.ink2,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                      color: pt.ink2,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;

        if (context.isDesktop) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: Row(
              children: [
                // ── Brand panel ──────────────────────────────────────────────
                const Expanded(child: AuthBrandPanel()),
                // ── Form panel ───────────────────────────────────────────────
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Top bar — create-account shortcut.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('New to PayPact?',
                                    style: PayPactTypography.bodyMd
                                        .copyWith(color: pt.ink2)),
                                const SizedBox(width: 14),
                                _PillButton(
                                  label: 'Create account',
                                  onTap: () => context.push(AppRoutes.signUp),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(56, 24, 56, 24),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: _buildForm(context, loading),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (loading)
                        Positioned.fill(
                          child: ColoredBox(
                            color: pt.bg.withValues(alpha: 0.6),
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: pt.bg,
          body: Stack(
            children: [
              const PpBackdropGlow(intensity: 0.12),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PpGlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop()),
                      const SizedBox(height: 36),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WELCOME BACK',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.accent, letterSpacing: 1.6)),
                            const SizedBox(height: 14),
                            Text("Hello, friend.\nLet's get you in.",
                                style: PayPactTypography.displayLg
                                    .copyWith(color: pt.ink)),
                            const SizedBox(height: 12),
                            Text(
                              "Sign in with your email — we'll keep things calm.",
                              style: PayPactTypography.bodyLg
                                  .copyWith(color: pt.ink2),
                            ),
                            const SizedBox(height: 28),
                            _Label(text: 'EMAIL'),
                            const SizedBox(height: 8),
                            _TextField(
                              controller: _emailCtrl,
                              icon: Icons.mail_outline_rounded,
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _Label(text: 'PASSWORD'),
                                Text('Forgot?',
                                    style: PayPactTypography.bodySm.copyWith(
                                        color: pt.accent,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _TextField(
                              controller: _passwordCtrl,
                              icon: Icons.lock_outline_rounded,
                              hint: '••••••••',
                              obscure: _obscure,
                              suffix: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: pt.ink3,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            PayPactButton(
                              onPressed: loading
                                  ? null
                                  : () => locator<AuthCubit>().signInWithEmail(
                                        _emailCtrl.text.trim(),
                                        _passwordCtrl.text,
                                      ),
                              label: loading ? 'Signing in…' : 'Sign in',
                              variant: PayPactButtonVariant.accent,
                              size: PayPactButtonSize.large,
                              isFullWidth: true,
                              rightIcon: Icons.arrow_forward_rounded,
                            ),
                            const SizedBox(height: 24),
                            Row(children: [
                              Expanded(child: Divider(color: pt.border)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('OR',
                                    style: PayPactTypography.label
                                        .copyWith(color: pt.ink3)),
                              ),
                              Expanded(child: Divider(color: pt.border)),
                            ]),
                            const SizedBox(height: 24),
                            PayPactButton(
                              onPressed: loading
                                  ? null
                                  : () =>
                                      locator<AuthCubit>().signInWithGoogle(),
                              label: 'Continue with Google',
                              variant: PayPactButtonVariant.secondary,
                              size: PayPactButtonSize.large,
                              isFullWidth: true,
                              leftIcon: Icons.g_mobiledata_rounded,
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: GestureDetector(
                                onTap: () => context.push(AppRoutes.signUp),
                                child: Text.rich(
                                  TextSpan(
                                    style: PayPactTypography.bodyMd
                                        .copyWith(color: pt.ink2),
                                    children: [
                                      const TextSpan(text: 'New to PayPact? '),
                                      TextSpan(
                                        text: 'Create an account',
                                        style: PayPactTypography.bodyMd
                                            .copyWith(
                                                color: pt.accent,
                                                fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Material(
      color: pt.surface,
      shape: RoundedRectangleBorder(
        borderRadius: PayPactRadius.full,
        side: BorderSide(color: pt.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: PayPactRadius.full,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(label,
              style: PayPactTypography.bodyMd
                  .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: PayPactTypography.label
            .copyWith(color: context.pt.ink3, letterSpacing: 1.5));
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: PayPactTypography.bodyLg.copyWith(color: pt.ink, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            PayPactTypography.bodyLg.copyWith(color: pt.ink3, fontSize: 15),
        prefixIcon: Icon(icon, color: pt.ink3, size: 18),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: pt.surface,
        border: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: BorderSide(color: pt.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: BorderSide(color: pt.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: BorderSide(color: pt.accent, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
