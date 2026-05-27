import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
        hintStyle: PayPactTypography.bodyLg.copyWith(color: pt.ink3, fontSize: 15),
        prefixIcon: Icon(icon, color: pt.ink3, size: 18),
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
