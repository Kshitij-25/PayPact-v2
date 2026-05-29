import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/features/auth/presentation/screens/auth_brand_panel.dart';
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

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  bool get _emailValid => _emailRegex.hasMatch(_emailCtrl.text.trim());
  bool get _nameValid => _nameCtrl.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    // Live-update validity checkmarks + password strength meter.
    for (final c in [_nameCtrl, _emailCtrl, _passwordCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  _PwStrength _strength(String pw) {
    if (pw.isEmpty) return const _PwStrength(0, '', '', '');
    final hasLen = pw.length >= 8;
    final hasMixed =
        RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[a-z]').hasMatch(pw);
    final hasNum = RegExp(r'\d').hasMatch(pw);
    final hasSym = RegExp(r'[^A-Za-z0-9]').hasMatch(pw);

    var score = 0;
    if (hasLen) score++;
    if (hasMixed) score++;
    if (hasNum) score++;
    if (hasSym) score++;

    const labels = ['', 'Weak', 'Fair', 'Strong', 'Excellent'];
    final present = <String>['${pw.length} characters'];
    if (hasMixed) present.add('mixed case');
    if (hasNum) present.add('one number');
    if (hasSym) present.add('a symbol');

    String suggestion;
    if (!hasLen) {
      suggestion = 'Use 8+ characters.';
    } else if (!hasMixed) {
      suggestion = 'Mix upper & lower case.';
    } else if (!hasNum) {
      suggestion = 'Add a number.';
    } else if (!hasSym) {
      suggestion = 'Add a symbol for excellent.';
    } else {
      suggestion = 'Looks excellent.';
    }
    return _PwStrength(score, labels[score], present.join(' · '), suggestion);
  }

  void _comingSoon(String provider) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$provider sign-up is coming soon.')),
      );

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

        // ── Mobile form content (phone layout) ───────────────────────────
        Widget mobileForm = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NEW HERE',
                style: PayPactTypography.label
                    .copyWith(color: pt.accent, letterSpacing: 1.6)),
            const SizedBox(height: 14),
            Text('Make a pact\nwith your money.',
                style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
            const SizedBox(height: 10),
            Text('A minute to set up. A lifetime of calmer splits.',
                style: PayPactTypography.bodyLg.copyWith(color: pt.ink2)),
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
            const SizedBox(height: 22),
            _AgreeCheckbox(
              agreed: _agreed,
              onTap: () => setState(() => _agreed = !_agreed),
            ),
            const SizedBox(height: 24),
            PayPactButton(
              onPressed: (loading || !_agreed)
                  ? null
                  : () => locator<AuthCubit>().createAccount(
                        _emailCtrl.text.trim(),
                        _passwordCtrl.text,
                        _nameCtrl.text.trim(),
                      ),
              label: loading ? 'Creating account…' : 'Create account',
              variant: PayPactButtonVariant.accent,
              size: PayPactButtonSize.large,
              isFullWidth: true,
              rightIcon: Icons.arrow_forward_rounded,
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
            PayPactButton(
              onPressed: loading
                  ? null
                  : () => locator<AuthCubit>().signInWithGoogle(),
              label: 'Sign up with Google',
              variant: PayPactButtonVariant.secondary,
              size: PayPactButtonSize.large,
              isFullWidth: true,
              leftIcon: Icons.g_mobiledata_rounded,
            ),
            const SizedBox(height: 28),
            Center(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.signIn),
                child: Text.rich(
                  TextSpan(
                    style: PayPactTypography.bodyMd.copyWith(color: pt.ink2),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in',
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        if (context.isDesktop) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: Row(
              children: [
                // ── Form panel ───────────────────────────────────────────
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
                            child: Row(
                              children: [
                                const AuthLogoRow(),
                                const Spacer(),
                                Text('Have an account?',
                                    style: PayPactTypography.bodyMd
                                        .copyWith(color: pt.ink2)),
                                const SizedBox(width: 14),
                                _PillButton(
                                  label: 'Sign in',
                                  onTap: () => context.go(AppRoutes.signIn),
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
                                      const BoxConstraints(maxWidth: 460),
                                  child: _buildDesktopForm(context, loading),
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
                // ── Benefits aside ───────────────────────────────────────
                const Expanded(child: _BenefitsAside()),
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
                        child: mobileForm,
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

  // ── Desktop form body ──────────────────────────────────────────────────
  Widget _buildDesktopForm(BuildContext context, bool loading) {
    final pt = context.pt;
    final pw = _passwordCtrl.text;
    final strength = _strength(pw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NEW HERE',
            style: PayPactTypography.label
                .copyWith(color: pt.accent, letterSpacing: 1.6)),
        const SizedBox(height: 14),
        Text('Make a pact with your money.',
            style: PayPactTypography.displayXl.copyWith(color: pt.ink)),
        const SizedBox(height: 10),
        Text('A minute to set up. A lifetime of calmer splits.',
            style: PayPactTypography.bodyLg.copyWith(color: pt.ink2)),
        const SizedBox(height: 32),
        // Name + email side by side.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(text: 'FULL NAME'),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: _nameCtrl,
                    icon: Icons.person_outline_rounded,
                    hint: 'Your name',
                    suffix: _nameValid
                        ? Icon(Icons.check_rounded,
                            color: pt.positive, size: 18)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(text: 'EMAIL'),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: _emailCtrl,
                    icon: Icons.mail_outline_rounded,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    suffix: _emailValid
                        ? Icon(Icons.check_rounded,
                            color: pt.positive, size: 18)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Label(text: 'PASSWORD'),
            if (strength.score > 0)
              Text(strength.label,
                  style: PayPactTypography.bodySm.copyWith(
                      color: pt.accent, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        _InputField(
          controller: _passwordCtrl,
          icon: Icons.lock_outline_rounded,
          hint: '8+ characters',
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
        if (strength.score > 0) ...[
          const SizedBox(height: 12),
          _StrengthBar(score: strength.score),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3),
              children: [
                TextSpan(text: '${strength.base}. '),
                TextSpan(
                    text: strength.suggestion,
                    style: TextStyle(
                        color: pt.accent, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _AgreeCheckbox(
          agreed: _agreed,
          onTap: () => setState(() => _agreed = !_agreed),
        ),
        const SizedBox(height: 24),
        PayPactButton(
          onPressed: (loading || !_agreed)
              ? null
              : () => locator<AuthCubit>().createAccount(
                    _emailCtrl.text.trim(),
                    _passwordCtrl.text,
                    _nameCtrl.text.trim(),
                  ),
          label: loading ? 'Creating account…' : 'Create account',
          variant: PayPactButtonVariant.accent,
          size: PayPactButtonSize.large,
          isFullWidth: true,
          leftIcon: Icons.arrow_forward_rounded,
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: Divider(color: pt.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR CONTINUE WITH',
                style: PayPactTypography.label
                    .copyWith(color: pt.ink3, letterSpacing: 1.4)),
          ),
          Expanded(child: Divider(color: pt.border)),
        ]),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Google',
                onTap: loading
                    ? null
                    : () => locator<AuthCubit>().signInWithGoogle(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: Icons.apple,
                label: 'Apple',
                onTap: loading ? null : () => _comingSoon('Apple'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'SSO',
                onTap: loading ? null : () => _comingSoon('SSO'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Password strength model ────────────────────────────────────────────────
class _PwStrength {
  const _PwStrength(this.score, this.label, this.base, this.suggestion);
  final int score; // 0..4
  final String label;
  final String base;
  final String suggestion;
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Row(
      children: List.generate(4, (i) {
        Color color;
        if (i < score) {
          color = pt.positive;
        } else if (i == score) {
          color = pt.accent.withValues(alpha: 0.55);
        } else {
          color = pt.border;
        }
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: PayPactRadius.full,
            ),
          ),
        );
      }),
    );
  }
}

// ── Benefits / testimonial aside ────────────────────────────────────────────
class _BenefitsAside extends StatelessWidget {
  const _BenefitsAside();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pt.bg,
        border: Border(left: BorderSide(color: pt.border)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.8),
                  radius: 1.0,
                  colors: [
                    pt.accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(56, 48, 56, 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHAT YOU GET',
                        style: GoogleFonts.geistMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.6,
                          color: pt.ink3,
                        )),
                    const SizedBox(height: 20),
                    _BenefitCard(
                      icon: Icons.do_not_disturb_on_outlined,
                      iconBg: pt.accentSoft,
                      iconColor: pt.accent,
                      title: 'Quiet by default',
                      subtitle: 'No social feed, no ads, no public history.',
                    ),
                    const SizedBox(height: 12),
                    _BenefitCard(
                      icon: Icons.bolt_rounded,
                      iconBg: pt.warnSoft,
                      iconColor: pt.warn,
                      title: 'Smart, kind nudges',
                      subtitle: 'Soft reminders that respect the room.',
                    ),
                    const SizedBox(height: 12),
                    _BenefitCard(
                      icon: Icons.touch_app_outlined,
                      iconBg: pt.positiveSoft,
                      iconColor: pt.positive,
                      title: 'Settle in a tap',
                      subtitle: 'Mark as paid, UPI, or PayPact wallet.',
                    ),
                    const SizedBox(height: 32),
                    const _TestimonialCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.lg,
        border: Border.all(color: pt.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: PayPactRadius.md,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: PayPactTypography.headingMd.copyWith(
                        color: pt.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: PayPactTypography.bodySm.copyWith(color: pt.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pt.ink,
        borderRadius: PayPactRadius.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"Splitwise grew up, took a deep breath, and started making good design choices."',
            style: GoogleFonts.geist(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: -0.02 * 21,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pt.accentSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('PS',
                    style: PayPactTypography.bodySm.copyWith(
                        color: pt.accentInk, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Priya Shah',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('Product designer, Mumbai',
                      style: PayPactTypography.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.50))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────
class _AgreeCheckbox extends StatelessWidget {
  const _AgreeCheckbox({required this.agreed, required this.onTap});
  final bool agreed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: agreed ? pt.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: agreed ? pt.accent : pt.borderStrong, width: 1.5),
            ),
            child: agreed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style:
                    PayPactTypography.bodySm.copyWith(color: pt.ink2, height: 1.5),
                children: [
                  const TextSpan(text: "I agree to PayPact's "),
                  TextSpan(
                    text: 'Terms',
                    style: TextStyle(
                        color: pt.ink,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy',
                    style: TextStyle(
                        color: pt.ink,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline),
                  ),
                  const TextSpan(
                      text:
                          '. PayPact will never share my data with brands or feeds.'),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final disabled = onTap == null;
    return Material(
      color: pt.surface,
      shape: RoundedRectangleBorder(
        borderRadius: PayPactRadius.full,
        side: BorderSide(color: pt.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: PayPactRadius.full,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: disabled ? pt.ink3 : pt.ink),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: PayPactTypography.bodyMd.copyWith(
                      color: disabled ? pt.ink3 : pt.ink,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
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
