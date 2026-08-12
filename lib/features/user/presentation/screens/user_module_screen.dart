import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_notification_button.dart';
import '../../../../shared/widgets/app_seal_badge.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../vendor/presentation/screens/vendor_workspace_screen.dart';

class UserModuleScreen extends StatelessWidget {
  const UserModuleScreen({
    super.key,
    this.autoOpenAddProduct = false,
    this.vendorSection = 'dashboard',
  });

  final bool autoOpenAddProduct;
  final String vendorSection;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user?.isVendor ?? false) {
      return VendorWorkspaceScreen(
        autoOpenAddProduct: autoOpenAddProduct,
        section: vendorSection,
      );
    }

    final firstName = _firstName(user?.fullName);
    final modules = _buyerModules;
    final isWeb = MediaQuery.sizeOf(context).width >= 1180;

    return Scaffold(
      appBar: isWeb
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Buyer Workspace'),
              actions: [
                const AppNotificationButton(),
                IconButton(
                  tooltip: 'Public view',
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.monitor_rounded),
                ),
              ],
            ),
      body: AppBackground(
        showTopGlow: false,
        child: isWeb
            ? _BuyerWebDashboard(firstName: firstName, modules: modules)
            : ResponsivePage(
                maxWidth: 1180,
                horizontalPadding: 0,
                topPadding: AppSpacing.sm,
                bottomPadding: AppSpacing.xxl,
                edgeToEdgeDesktopOnly: true,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    _BuyerHeader(
                      firstName: firstName,
                      moduleCount: modules.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(count: modules.length),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 980
                            ? 3
                            : constraints.maxWidth >= 640
                            ? 2
                            : 1;
                        final gap = AppSpacing.md;
                        final cardWidth =
                            (constraints.maxWidth - (gap * (columns - 1))) /
                            columns;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final module in modules)
                              SizedBox(
                                width: cardWidth,
                                child: _BuyerModuleCard(
                                  module: module,
                                  onTap: () => context.go(module.route),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  static String _firstName(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) {
      return 'Buyer';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _BuyerWebDashboard extends StatelessWidget {
  const _BuyerWebDashboard({required this.firstName, required this.modules});

  final String firstName;
  final List<_BuyerModule> modules;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 48),
      children: [
        _BuyerWebHero(firstName: firstName),
        const SizedBox(height: 24),
        const _BuyerJourneyStrip(),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WebSectionHeading(
                    eyebrow: 'COMMUNITY SERVICES',
                    title: 'What would you like to do?',
                    subtitle:
                        'Use verified market information and community tools in one workspace.',
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 14.0;
                      final width = (constraints.maxWidth - gap) / 2;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final module in modules)
                            SizedBox(
                              width: width,
                              child: _BuyerWebServiceCard(
                                module: module,
                                onTap: () => context.go(module.route),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 330,
              child: Column(
                children: [
                  const _BuyerTrustPanel(),
                  const SizedBox(height: 16),
                  _BuyerReportPanel(
                    onScan: () => context.go('/scan-qr'),
                    onReports: () => context.go('/reports'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BuyerWebHero extends StatelessWidget {
  const _BuyerWebHero({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF142640), Color(0xFF213A60)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF385173)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LINGAYEN MARKET INTELLIGENCE',
                style: TextStyle(
                  color: Color(0xFFFF82AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Good day, $firstName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Compare local prices, find verified stores, and report unusual pricing with confidence.',
                style: TextStyle(
                  color: Color(0xFFC7D2E3),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go('/commodities'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Color(0xFF647084)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search rice, fish, meat, eggs, or vegetables',
                              style: TextStyle(color: Color(0xFF647084)),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF8B1244),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroShortcut(
                    icon: Icons.inventory_2_outlined,
                    label: 'Browse all prices',
                    onTap: () => context.go('/commodities'),
                  ),
                  _HeroShortcut(
                    icon: Icons.storefront_outlined,
                    label: 'Find a store',
                    onTap: () => context.go('/stores'),
                  ),
                  _HeroShortcut(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Report with QR',
                    onTap: () => context.go('/scan-qr'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Container(
          width: 190,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: .12)),
          ),
          child: const Column(
            children: [
              AppSealBadge(size: 72, padding: 5, showFrame: false),
              SizedBox(height: 14),
              Text(
                'Verified local data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Municipality of Lingayen',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFC7D2E3), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeroShortcut extends StatelessWidget {
  const _HeroShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFF8EB2), size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BuyerJourneyStrip extends StatelessWidget {
  const _BuyerJourneyStrip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: const Row(
      children: [
        _JourneyStep(
          number: '01',
          icon: Icons.search_rounded,
          title: 'Find a commodity',
          subtitle: 'Search verified local records',
        ),
        _JourneyConnector(),
        _JourneyStep(
          number: '02',
          icon: Icons.compare_arrows_rounded,
          title: 'Compare prices',
          subtitle: 'Check current price against SRP',
        ),
        _JourneyConnector(),
        _JourneyStep(
          number: '03',
          icon: Icons.bookmark_outline_rounded,
          title: 'Save essentials',
          subtitle: 'Watch commodities you buy often',
        ),
        _JourneyConnector(),
        _JourneyStep(
          number: '04',
          icon: Icons.flag_outlined,
          title: 'Report concerns',
          subtitle: 'Use the store QR for accuracy',
        ),
      ],
    ),
  );
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            Positioned(
              right: -5,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondaryFor(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Icon(
      Icons.arrow_forward_rounded,
      size: 18,
      color: AppColors.textSecondaryFor(context).withValues(alpha: .55),
    ),
  );
}

class _WebSectionHeading extends StatelessWidget {
  const _WebSectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondaryFor(context)),
      ),
    ],
  );
}

class _BuyerWebServiceCard extends StatelessWidget {
  const _BuyerWebServiceCard({required this.module, required this.onTap});
  final _BuyerModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 154,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -26,
              child: Icon(
                module.icon,
                size: 112,
                color: module.color.withValues(alpha: .055),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: module.color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(module.icon, color: module.color, size: 20),
                    ),
                    const Spacer(),
                    const Icon(Icons.north_east_rounded, size: 19),
                  ],
                ),
                const Spacer(),
                Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _BuyerTrustPanel extends StatelessWidget {
  const _BuyerTrustPanel();

  @override
  Widget build(BuildContext context) => _BuyerSidePanel(
    title: 'Buy with confidence',
    subtitle: 'Understand every price before purchasing.',
    children: const [
      _BuyerGuideRow(
        Icons.price_check_rounded,
        'Compare with SRP',
        'See the official suggested retail price beside current records.',
      ),
      _BuyerGuideRow(
        Icons.storefront_rounded,
        'Choose verified stores',
        'Browse registered shops and their latest commodity prices.',
      ),
      _BuyerGuideRow(
        Icons.notifications_active_outlined,
        'Track essentials',
        'Use your watchlist for meaningful price movement updates.',
      ),
    ],
  );
}

class _BuyerReportPanel extends StatelessWidget {
  const _BuyerReportPanel({required this.onScan, required this.onReports});
  final VoidCallback onScan;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) => _BuyerSidePanel(
    title: 'See an unusual price?',
    subtitle: 'Send a store-linked report to the market team.',
    children: [
      FilledButton.icon(
        onPressed: onScan,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan store QR'),
      ),
      const SizedBox(height: 9),
      OutlinedButton.icon(
        onPressed: onReports,
        icon: const Icon(Icons.flag_outlined),
        label: const Text('View my reports'),
      ),
    ],
  );
}

class _BuyerSidePanel extends StatelessWidget {
  const _BuyerSidePanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondaryFor(context),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class _BuyerGuideRow extends StatelessWidget {
  const _BuyerGuideRow(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondaryFor(context),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

const List<_BuyerModule> _buyerModules = [
  _BuyerModule(
    title: 'Products',
    description: 'Browse commodities, SRP details, categories, and trends.',
    route: '/commodities',
    icon: Icons.inventory_2_rounded,
    color: AppColors.primary,
  ),
  _BuyerModule(
    title: 'Stores',
    description: 'Explore markets, verified shops, and local price updates.',
    route: '/stores',
    icon: Icons.storefront_rounded,
    color: AppColors.sky,
  ),
  _BuyerModule(
    title: 'Reports',
    description: 'Scan a shop QR, submit concerns, and track report status.',
    route: '/reports',
    icon: Icons.flag_rounded,
    color: AppColors.warning,
  ),
  _BuyerModule(
    title: 'Watchlist',
    description: 'Follow essentials and receive price movement alerts.',
    route: '/watchlist',
    icon: Icons.bookmark_rounded,
    color: AppColors.primarySoft,
  ),
];

class _BuyerHeader extends StatelessWidget {
  const _BuyerHeader({required this.firstName, required this.moduleCount});

  final String firstName;
  final int moduleCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: (useDark ? AppColors.darkPrimarySoft : AppColors.primary)
                  .withValues(alpha: useDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const AppSealBadge(size: 36, padding: 3, showFrame: false),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use buyer tools to browse commodities, report overpricing, and track essentials.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _HeaderChip(
                      icon: Icons.apps_rounded,
                      label: '$moduleCount tools',
                    ),
                    const _HeaderChip(
                      icon: Icons.verified_rounded,
                      label: 'Buyer access',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.isDark(context)
        ? AppColors.darkPrimarySoft
        : AppColors.primaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: AppColors.isDark(context) ? 0.18 : 0.08,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Buyer tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '$count available',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BuyerModuleCard extends StatelessWidget {
  const _BuyerModuleCard({required this.module, required this.onTap});

  final _BuyerModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);
    final color = useDark && module.color == AppColors.sky
        ? AppColors.darkPrimarySoft
        : module.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 136),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.borderFor(
                  context,
                ).withValues(alpha: useDark ? 0.72 : 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: useDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(module.icon, color: color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimaryFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        module.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryFor(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryFor(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyerModule {
  const _BuyerModule({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
  final Color color;
}
