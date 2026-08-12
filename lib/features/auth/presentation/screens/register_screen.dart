import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_split_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialRole = 'user'});

  final String initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final useDesktopSplit = kIsWeb && MediaQuery.sizeOf(context).width >= 1080;
    final compactHeight = MediaQuery.sizeOf(context).height < 820;

    return Scaffold(
      appBar: useDesktopSplit
          ? null
          : AppBar(
              leading: BackButton(
                onPressed: () => context.go(_authPageRoute(context, '/login')),
              ),
            ),
      body: LoadingOverlay(
        isLoading: auth.isBusy,
        child: AppBackground(
          child: AuthSplitLayout(
            mobileTopSafeArea: false,
            desktopFormFirst: false,
            mobileChild: _buildMobileContent(theme, auth, compactHeight),
            desktopAside: const AuthShowcasePanel(
              showHeader: true,
              badge: 'COMMUNITY ACCESS',
              title: 'Join a more transparent local marketplace.',
              subtitle:
                  'Create your community account to follow essential commodities, receive alerts, and report unusual prices.',
              stats: [
                AuthShowcaseStat(value: 'Free', label: 'Community access'),
                AuthShowcaseStat(value: 'Live', label: 'Price updates'),
                AuthShowcaseStat(value: 'Safe', label: 'Managed roles'),
              ],
              features: [
                AuthShowcaseFeature(
                  icon: Icons.shield_outlined,
                  title: 'Your own secure account',
                  description:
                      'Keep your saved commodities, alerts, and submitted reports available across sessions.',
                ),
                AuthShowcaseFeature(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Personal price watchlist',
                  description:
                      'Watchlists, reports, notifications, and profile data stay attached to your shared account.',
                ),
                AuthShowcaseFeature(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Verified vendor access',
                  description:
                      'Vendor accounts are created and managed by administrators so store ownership and reporting stay accurate.',
                ),
              ],
              footer: _DesktopInfoCard(
                icon: Icons.info_outline_rounded,
                title: 'Need the admin workspace?',
                message:
                    'This page creates community accounts. Vendor access is issued only after shop verification.',
              ),
            ),
            desktopFormChild: _buildDesktopContent(theme, auth, compactHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileContent(
    ThemeData theme,
    AuthController auth,
    bool compactHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: AppSealBadge(size: compactHeight ? 64 : 74, padding: 5)),
        SizedBox(height: compactHeight ? AppSpacing.lg : AppSpacing.xl),
        Text(
          'Create your account',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Create your shared account once and start tracking commodity prices.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildRegisterCard(theme, auth, compactHeight),
      ],
    );
  }

  Widget _buildDesktopContent(
    ThemeData theme,
    AuthController auth,
    bool compactHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your community account',
          style:
              (compactHeight
                      ? theme.textTheme.headlineLarge
                      : theme.textTheme.displaySmall)
                  ?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                    height: 1.06,
                  ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Save commodities, receive price alerts, and submit community reports from one secure account.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondaryFor(context),
            height: 1.5,
          ),
        ),
        SizedBox(height: compactHeight ? AppSpacing.lg : AppSpacing.xl),
        _buildRegisterCard(theme, auth, compactHeight),
      ],
    );
  }

  Widget _buildRegisterCard(
    ThemeData theme,
    AuthController auth,
    bool compactHeight,
  ) {
    final useDark = AppColors.isDark(context);
    return Container(
      padding: EdgeInsets.all(compactHeight ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(
          context,
        ).withValues(alpha: useDark ? 0.96 : 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMUNITY ACCESS',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your PriceWatch account',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Fill in your details to start tracking prices locally.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _fullNameController,
                label: 'Full name',
                validator: (value) =>
                    Validators.requiredField(value, label: 'Full name'),
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                validator: Validators.password,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                validator: (value) =>
                    Validators.confirmation(value, _passwordController.text),
                obscureText: true,
                prefixIcon: Icons.verified_user_outlined,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  'Vendor accounts are created by administrators only. Community users can register here directly.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ErrorBanner(message: auth.errorMessage!),
              ],
              SizedBox(height: compactHeight ? AppSpacing.lg : AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: 'Create account',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: _submit,
                  isLoading: auth.isBusy,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      context.go(_authPageRoute(context, '/login')),
                  child: const Text('Back to login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: 'user',
    );

    if (success && mounted) {
      context.go(_postAuthRoute(context));
    }
  }

  static String _postAuthRoute(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final isWebAdmin =
        kIsWeb &&
        (context.read<AuthController>().currentUser?.isAdmin ?? false);
    if (from == null ||
        from.isEmpty ||
        from.startsWith('/login') ||
        from.startsWith('/register') ||
        from.startsWith('/splash')) {
      return isWebAdmin ? '/admin' : '/modules';
    }
    if (isWebAdmin &&
        (from == '/home' ||
            from == '/watchlist' ||
            from == '/reports' ||
            from == '/profile')) {
      return '/admin';
    }
    return from;
  }

  static String _authPageRoute(BuildContext context, String path) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from == null || from.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: {'from': from}).toString();
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: useDark ? const Color(0xFF4A1E31) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: useDark ? const Color(0xFF8C3A60) : const Color(0xFFFECDD3),
        ),
      ),
      child: Text(message),
    );
  }
}

class _DesktopInfoCard extends StatelessWidget {
  const _DesktopInfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: useDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
