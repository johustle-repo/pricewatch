import 'package:flutter/material.dart';
import '../../../../shared/widgets/pricewatch_help.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Profile'),
              actions: [const AppNotificationButton()],
            ),
      body: user == null
          ? const SizedBox.shrink()
          : AppBackground(
              child: ResponsivePage(
                maxWidth: 1040,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: ListView(
                  children: [
                    const PriceWatchHelp(),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradientFor(context),
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.glowStrong,
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 360;
                          final avatar = Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Text(
                                _initialsFor(user.fullName),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          );
                          final info = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                user.email,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppStatusBadge(
                                label: user.isAdmin
                                    ? 'Admin account'
                                    : 'Community user',
                                color: Colors.white,
                                icon: user.isAdmin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.verified_user_rounded,
                              ),
                            ],
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                avatar,
                                const SizedBox(height: 16),
                                info,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              avatar,
                              const SizedBox(width: 16),
                              Expanded(child: info),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Account settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSurfaceCard(
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.edit_outlined,
                            title: 'Edit profile',
                            subtitle: 'Update your name and email',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          const Divider(height: 1),
                          _SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Change password',
                            subtitle: 'Refresh your local login credentials',
                            onTap: () => context.push('/profile/password'),
                          ),
                          const Divider(height: 1),
                          _SettingsTile(
                            icon: Icons.mark_email_read_outlined,
                            title: 'Email password reset',
                            subtitle:
                                'Send a secure reset link to ${user.email}',
                            onTap: () async {
                              final ok = await context
                                  .read<ProfileController>()
                                  .sendPasswordReset();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Password reset email sent.'
                                          : context
                                                    .read<ProfileController>()
                                                    .error ??
                                                'Could not send reset email.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const Divider(height: 1),
                          _SettingsTile(
                            icon: Icons.flag_outlined,
                            title: 'My reports',
                            subtitle: 'Review your submitted price complaints',
                            onTap: () => context.go('/reports'),
                          ),
                          const Divider(height: 1),
                          _SettingsTile(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notifications',
                            subtitle: 'Check alerts and report updates',
                            onTap: () => context.push('/notifications'),
                          ),
                        ],
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppSurfaceCard(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.isDark(context)
                              ? const [Color(0xFF442032), Color(0xFF261620)]
                              : const [Color(0xFFFFEAF4), Color(0xFFFFFFFF)],
                        ),
                        borderColor: AppColors.primary.withValues(alpha: 0.22),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 360;
                            final icon = Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.dashboard_customize_rounded,
                                color: AppColors.primaryDark,
                              ),
                            );
                            final text = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin dashboard',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage categories, prices, stores, reports, and analytics.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      icon,
                                      const SizedBox(width: 14),
                                      Expanded(child: text),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () => context.push('/admin'),
                                      child: const Text('Open'),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                icon,
                                const SizedBox(width: 14),
                                Expanded(child: text),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () => context.push('/admin'),
                                  child: const Text('Open'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppSurfaceCard(
                      borderColor: Colors.red.withValues(alpha: .25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Privacy & account',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your watchlist, reports, and notifications are visible only to your account and authorized market staff.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _confirmDeactivation(context, user.id),
                            icon: const Icon(Icons.person_off_outlined),
                            label: const Text('Deactivate my account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      onPressed: () async {
                        await context.read<AuthController>().logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'PW';
    }
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$last'.toUpperCase();
  }

  static Future<void> _confirmDeactivation(
    BuildContext context,
    int? userId,
  ) async {
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate account?'),
        content: const Text(
          'You will be signed out and this account will no longer be usable. Your submitted market reports remain in the audit record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ProfileController>().deactivateAccount(
      userId,
    );
    if (!context.mounted) return;
    if (ok) {
      await context.read<AuthController>().logout();
      if (context.mounted) context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ProfileController>().error ??
                'Account could not be deactivated. Sign in again and retry.',
          ),
        ),
      );
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.backgroundAltFor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
