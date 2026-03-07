import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  backgroundImage: user?.photoUrl != null
                      ? CachedNetworkImageProvider(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          user?.displayName.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                      color: PaypactColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            onTap: () {},
          ),
          _buildTile(
            context,
            icon: Icons.language_outlined,
            title: 'Currency & Language',
            onTap: () {},
          ),
          _buildTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            color: Theme.of(context).colorScheme.error,
            onTap: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading:
          Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: color == null
          ? const Icon(Icons.chevron_right, color: PaypactColors.textSecondary)
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onTap,
    );
  }
}
