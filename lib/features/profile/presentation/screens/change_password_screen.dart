import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;
    final controller = context.watch<ProfileController>();

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Change Password'),
              actions: const [AppNotificationButton(), SizedBox(width: 8)],
            ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.glowStrong,
                        blurRadius: 28,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure your account',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Use a strong password to protect local sign-in access on this device.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppSurfaceCard(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _currentController,
                        label: 'Current password',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (value) => Validators.requiredField(
                          value,
                          label: 'Current password',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _newController,
                        label: 'New password',
                        obscureText: true,
                        prefixIcon: Icons.key_outlined,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _confirmController,
                        label: 'Confirm password',
                        obscureText: true,
                        prefixIcon: Icons.verified_user_outlined,
                        validator: (value) =>
                            Validators.confirmation(value, _newController.text),
                      ),
                      if (controller.error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: 'Update password',
                  icon: Icons.shield_outlined,
                  isLoading: controller.isLoading,
                  onPressed: controller.isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null) {
      return;
    }

    final success = await context.read<ProfileController>().changePassword(
      userId: userId,
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
      Navigator.of(context).pop();
    }
  }
}
