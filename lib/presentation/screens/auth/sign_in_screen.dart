import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Sign in failed'),
                backgroundColor: PaypactColors.danger,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: 16),
                _buildTagline(),
                const Spacer(flex: 3),
                _buildGoogleSignInButton(context),
                const SizedBox(height: 16),
                _buildTermsText(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [PaypactColors.primary, PaypactColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Paypact',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: PaypactColors.textPrimary,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return const Text(
      'Split expenses effortlessly.\nSettle debts with zero drama.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: PaypactColors.textSecondary,
        height: 1.6,
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: state.isLoading
                ? null
                : () =>
                    context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Brand(Brands.google),
            label: Text(
              state.isLoading ? 'Signing in...' : 'Continue with Google',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: PaypactColors.textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: PaypactColors.divider, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: PaypactColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}
