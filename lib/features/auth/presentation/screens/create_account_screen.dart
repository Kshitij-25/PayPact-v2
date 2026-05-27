import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _agreed = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
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
                            Text('NEW HERE',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.accent, letterSpacing: 1.6)),
                            const SizedBox(height: 14),
                            Text('Make a pact\nwith your money.',
                                style: PayPactTypography.displayLg
                                    .copyWith(color: pt.ink)),
                            const SizedBox(height: 10),
                            Text(
                                'A minute to set up. A lifetime of calmer splits.',
                                style: PayPactTypography.bodyLg
                                    .copyWith(color: pt.ink2)),
                            const SizedBox(height: 28),
                            _Label(text: 'FULL NAME'),
                            const SizedBox(height: 8),
                            _InputField(
                                controller: _nameCtrl,
                                icon: Icons.person_outline_rounded,
                                hint: 'Your name'),
                            const SizedBox(height: 14),
                            _Label(text: 'EMAIL'),
                            const SizedBox(height: 8),
                            _InputField(
                                controller: _emailCtrl,
                                icon: Icons.mail_outline_rounded,
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            _Label(text: 'PASSWORD'),
                            const SizedBox(height: 8),
                            _InputField(
                              controller: _passwordCtrl,
                              icon: Icons.lock_outline_rounded,
                              hint: '8+ characters',
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
                            const SizedBox(height: 22),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _agreed = !_agreed),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _agreed
                                          ? pt.accent
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _agreed
                                            ? pt.accent
                                            : pt.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _agreed
                                        ? const Icon(Icons.check_rounded,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        style: PayPactTypography.bodySm
                                            .copyWith(
                                                color: pt.ink2, height: 1.5),
                                        children: [
                                          const TextSpan(
                                              text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms',
                                            style: TextStyle(
                                                color: pt.ink,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration
                                                    .underline),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                                color: pt.ink,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration
                                                    .underline),
                                          ),
                                          const TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            PayPactButton(
                              onPressed: (loading || !_agreed)
                                  ? null
                                  : () =>
                                      locator<AuthCubit>().createAccount(
                                        _emailCtrl.text.trim(),
                                        _passwordCtrl.text,
                                        _nameCtrl.text.trim(),
                                      ),
                              label: loading
                                  ? 'Creating account…'
                                  : 'Create account',
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
                              label: 'Sign up with Google',
                              variant: PayPactButtonVariant.secondary,
                              size: PayPactButtonSize.large,
                              isFullWidth: true,
                              leftIcon: Icons.g_mobiledata_rounded,
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: GestureDetector(
                                onTap: () => context.pop(),
                                child: Text.rich(
                                  TextSpan(
                                    style: PayPactTypography.bodyMd
                                        .copyWith(color: pt.ink2),
                                    children: [
                                      const TextSpan(
                                          text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Sign in',
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
  Widget build(BuildContext context) => Text(text,
      style: PayPactTypography.label
          .copyWith(color: context.pt.ink3, letterSpacing: 1.5));
}

class _InputField extends StatelessWidget {
  const _InputField({
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
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: pt.surface,
        border: Border.all(color: pt.border),
        borderRadius: PayPactRadius.md,
        boxShadow: pt.shadowSm,
      ),
      child: Row(children: [
        Icon(icon, color: pt.ink3, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style:
                PayPactTypography.bodyLg.copyWith(color: pt.ink, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: PayPactTypography.bodyLg
                  .copyWith(color: pt.ink3, fontSize: 15),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
            ),
          ),
        ),
        if (suffix != null) suffix!,
      ]),
    );
  }
}
