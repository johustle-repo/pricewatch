import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_split_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);
    final compactHeight = MediaQuery.sizeOf(context).height < 820;
    final useDark = AppColors.isDark(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (useDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: LoadingOverlay(
          isLoading: auth.isBusy,
          child: AppBackground(
            child: AuthSplitLayout(
              mobileTopSafeArea: true,
              mobileChild: _buildMobileContent(theme, auth, compactHeight),
              desktopAside: AuthShowcasePanel(
                badge: 'LINGAYEN MARKET INTELLIGENCE',
                title: 'Reliable local prices. Better market decisions.',
                subtitle:
                    'One secure workspace for commodity monitoring, community reports, and municipal market oversight.',
                stats: const [
                  AuthShowcaseStat(value: 'Live', label: 'Price records'),
                  AuthShowcaseStat(value: 'SRP', label: 'Compliance view'),
                  AuthShowcaseStat(value: '1', label: 'Shared workspace'),
                ],
                features: const [
                  AuthShowcaseFeature(
                    icon: Icons.query_stats_rounded,
                    title: 'See price movement clearly',
                    description:
                        'Compare current prices, previous records, and published SRP in one view.',
                  ),
                  AuthShowcaseFeature(
                    icon: Icons.groups_2_outlined,
                    title: 'Connected community reporting',
                    description:
                        'Submit and review market concerns with transparent status updates.',
                  ),
                  AuthShowcaseFeature(
                    icon: Icons.verified_user_outlined,
                    title: 'Role-based secure access',
                    description:
                        'Community, vendor, and administrator tools stay separated and protected.',
                  ),
                ],
                // footer: _DesktopHintCard(
                //   icon: Icons.lock_clock_rounded,
                //   title: 'Persistent browser demo',
                //   message:
                //       'Your web data is stored in browser IndexedDB, so using the same local web port keeps the same seeded database.',
                // ),
              ),
              desktopFormChild: _buildDesktopContent(
                theme,
                auth,
                compactHeight,
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: _BrandMark(
            size: compactHeight ? 74 : 84,
            radius: compactHeight ? 24 : 28,
          ),
        ),
        SizedBox(height: compactHeight ? AppSpacing.xl : AppSpacing.xxl),
        Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to monitor commodity prices and report overpricing with confidence.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildLoginCard(theme, auth, compactHeight),
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
          'Welcome back',
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
          'Access current market prices, saved watchlists, reports, and the workspace assigned to your account.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondaryFor(context),
            height: 1.5,
          ),
        ),
        SizedBox(height: compactHeight ? AppSpacing.lg : AppSpacing.xl),
        _buildLoginCard(theme, auth, compactHeight),
      ],
    );
  }

  Widget _buildLoginCard(
    ThemeData theme,
    AuthController auth,
    bool compactHeight,
  ) {
    final useDark = AppColors.isDark(context);
    return Container(
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
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compactHeight ? AppSpacing.lg : AppSpacing.xl),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACCOUNT ACCESS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to PriceWatch',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use the email and password registered to your account.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ErrorBanner(message: auth.errorMessage!),
                ],
                SizedBox(height: compactHeight ? AppSpacing.lg : AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    label: 'Login',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _submit,
                    isLoading: auth.isBusy,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.go(_authPageRoute(context, '/register')),
                    child: const Text('Create account'),
                  ),
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

    final auth = context.read<AuthController>();
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: useDark ? const Color(0xFF4A1E31) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: useDark ? const Color(0xFF8C3A60) : const Color(0xFFFECDD3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradientFor(context),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: useDark ? 0.24 : 0.16),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AppSealBadge(size: size - 28, padding: 2, showFrame: false),
    );
  }
}
