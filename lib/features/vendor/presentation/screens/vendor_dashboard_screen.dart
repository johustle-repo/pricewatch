import 'package:flutter/material.dart';
import '../../../../shared/widgets/pricewatch_help.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/ui_models.dart';

class VendorDashboardData {
  const VendorDashboardData({
    required this.storeName,
    required this.location,
    required this.products,
    required this.staleCount,
    required this.aboveSrpCount,
    required this.pendingReportCount,
  });

  final String storeName;
  final String location;
  final List<StoreCommodityPrice> products;
  final int staleCount;
  final int aboveSrpCount;
  final int pendingReportCount;
}

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({
    super.key,
    required this.data,
    required this.onAddProduct,
    required this.onRefresh,
  });

  final VendorDashboardData data;
  final VoidCallback onAddProduct;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      if (constraints.maxWidth < 600) {
        return _MobileVendorDashboard(
          data: data,
          onAddProduct: onAddProduct,
          onRefresh: onRefresh,
        );
      }
      final pagePadding = compact ? 16.0 : 28.0;
      return ListView(
        padding: EdgeInsets.fromLTRB(pagePadding, 24, pagePadding, 56),
        children: [
          _Hero(data: data, onRefresh: onRefresh, onAddProduct: onAddProduct),
          const SizedBox(height: 22),
          _KpiGrid(data: data),
          const SizedBox(height: 22),
          if (constraints.maxWidth >= 1080)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _PriceRegister(products: data.products),
                ),
                const SizedBox(width: 22),
                SizedBox(
                  width: 330,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AttentionPanel(data: data),
                      const SizedBox(height: 22),
                      _QuickActions(onAddProduct: onAddProduct),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _AttentionPanel(data: data),
            const SizedBox(height: 22),
            _QuickActions(onAddProduct: onAddProduct),
            const SizedBox(height: 22),
            _PriceRegister(products: data.products),
          ],
          const SizedBox(height: 22),
          const VendorDocumentLegend(),
        ],
      );
    },
  );
}

class _MobileVendorDashboard extends StatelessWidget {
  const _MobileVendorDashboard({
    required this.data,
    required this.onAddProduct,
    required this.onRefresh,
  });

  final VendorDashboardData data;
  final VoidCallback onAddProduct;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final attention =
        data.staleCount + data.aboveSrpCount + data.pendingReportCount;
    return ListView(
      key: const Key('vendor-mobile-dashboard'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        const VendorDocumentLegend(),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF172A49), Color(0xFF8B1244)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFFF8AB0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VENDOR STORE',
                          style: TextStyle(
                            color: Color(0xFFFFA1BF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        Text(
                          data.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh dashboard',
                    onPressed: onRefresh,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: .1),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFD8E0EC), height: 1.35),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: _MobileHeroLabel(
                      icon: Icons.verified_rounded,
                      label: 'Verified',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MobileHeroLabel(
                      icon: attention == 0
                          ? Icons.check_circle_outline_rounded
                          : Icons.notification_important_outlined,
                      label: attention == 0
                          ? 'All current'
                          : '$attention alerts',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add price'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/vendor/products'),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Products'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _MobileSectionTitle(
          title: 'Store snapshot',
          subtitle: 'What needs your attention today',
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.48,
          children: [
            _MobileMetric(
              'Products',
              data.products.length,
              Icons.inventory_2_outlined,
              const Color(0xFF38BDF8),
            ),
            _MobileMetric(
              'Update prices',
              data.staleCount,
              Icons.schedule_rounded,
              const Color(0xFFF59E0B),
            ),
            _MobileMetric(
              'Above SRP',
              data.aboveSrpCount,
              Icons.trending_up_rounded,
              const Color(0xFFFB7185),
            ),
            _MobileMetric(
              'Reports',
              data.pendingReportCount,
              Icons.flag_outlined,
              const Color(0xFFA78BFA),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _MobileProducts(products: data.products),
        const SizedBox(height: 20),
        const _MobileSectionTitle(
          title: 'Vendor tools',
          subtitle: 'Manage your store from one place',
        ),
        const SizedBox(height: 10),
        _MobileTool(
          icon: Icons.assignment_outlined,
          title: 'Review reports',
          subtitle: '${data.pendingReportCount} pending',
          onTap: () => context.go('/reports'),
        ),
        _MobileTool(
          icon: Icons.qr_code_2_rounded,
          title: 'Store QR',
          subtitle: 'Display your verified store code',
          onTap: () => context.go('/vendor/qr'),
        ),
      ],
    );
  }
}

class _MobileHeroLabel extends StatelessWidget {
  const _MobileHeroLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF9BBB)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MobileSectionTitle extends StatelessWidget {
  const _MobileSectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondaryFor(context),
          fontSize: 13,
        ),
      ),
    ],
  );
}

class _MobileMetric extends StatelessWidget {
  const _MobileMetric(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondaryFor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MobileProducts extends StatelessWidget {
  const _MobileProducts({required this.products});
  final List<StoreCommodityPrice> products;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: _MobileSectionTitle(
              title: 'Current prices',
              subtitle: 'Latest store price records',
            ),
          ),
          TextButton(
            onPressed: () => context.go('/vendor/products'),
            child: const Text('View all'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (products.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: const Text(
            'No prices yet. Add your first commodity price.',
            textAlign: TextAlign.center,
          ),
        )
      else
        for (final product in products.take(4))
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.commodityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'SRP ${AppFormatters.currency(product.srp)}',
                        style: TextStyle(
                          color: AppColors.textSecondaryFor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.currency(product.latestPrice),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.latestPrice > product.srp
                          ? 'Above SRP'
                          : 'Within SRP',
                      style: TextStyle(
                        color: product.latestPrice > product.srp
                            ? const Color(0xFFFB7185)
                            : const Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    ],
  );
}

class _MobileTool extends StatelessWidget {
  const _MobileTool({
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.data,
    required this.onRefresh,
    required this.onAddProduct,
  });
  final VendorDashboardData data;
  final VoidCallback onRefresh;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 880;
      final info = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VENDOR OPERATIONS',
              style: TextStyle(
                color: Color(0xFFFF7CA5),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.storeName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.location,
              style: const TextStyle(color: Color(0xFFC4CFE0), fontSize: 15),
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _HeroBadge(Icons.verified_rounded, 'Verified vendor'),
                _HeroBadge(Icons.cloud_done_outlined, 'Live market data'),
              ],
            ),
          ],
        ),
      );
      final actions = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 160,
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 160,
            child: FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add price'),
            ),
          ),
        ],
      );
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF13223D), Color(0xFF1D3456)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF345071)),
        ),
        child: desktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 28),
                  actions,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 22), actions],
              ),
      );
    },
  );
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF7CA5)),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});
  final VendorDashboardData data;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1050
          ? 4
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      const gap = 14.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          _Kpi(
            width,
            'Listed products',
            '${data.products.length}',
            Icons.inventory_2_outlined,
            const Color(0xFF38BDF8),
          ),
          _Kpi(
            width,
            'Need price update',
            '${data.staleCount}',
            Icons.schedule_rounded,
            const Color(0xFFF59E0B),
          ),
          _Kpi(
            width,
            'Above SRP',
            '${data.aboveSrpCount}',
            Icons.trending_up_rounded,
            const Color(0xFFFB7185),
          ),
          _Kpi(
            width,
            'Pending reports',
            '${data.pendingReportCount}',
            Icons.flag_outlined,
            const Color(0xFFA78BFA),
          ),
        ],
      );
    },
  );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.width, this.label, this.value, this.icon, this.color);
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({required this.data});
  final VendorDashboardData data;
  @override
  Widget build(BuildContext context) {
    final total =
        data.staleCount + data.aboveSrpCount + data.pendingReportCount;
    return _Panel(
      title: 'Needs attention',
      subtitle: total == 0
          ? 'Your store records are healthy.'
          : '$total item(s) require review.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AlertRow(
            Icons.schedule_rounded,
            'Outdated prices',
            data.staleCount,
            const Color(0xFFF59E0B),
          ),
          _AlertRow(
            Icons.trending_up_rounded,
            'Above SRP',
            data.aboveSrpCount,
            const Color(0xFFFB7185),
          ),
          _AlertRow(
            Icons.flag_outlined,
            'Open reports',
            data.pendingReportCount,
            const Color(0xFFA78BFA),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow(this.icon, this.label, this.count, this.color);
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAddProduct});
  final VoidCallback onAddProduct;
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Quick actions',
    subtitle: 'Common vendor operations.',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Action(Icons.add_chart_rounded, 'Record new price', onAddProduct),
        _Action(
          Icons.inventory_2_outlined,
          'Manage products',
          () => context.go('/vendor/products'),
        ),
        _Action(
          Icons.assignment_outlined,
          'Review reports',
          () => context.go('/reports'),
        ),
        _Action(
          Icons.qr_code_2_rounded,
          'Open store QR',
          () => context.go('/vendor/qr'),
        ),
      ],
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
    onTap: onTap,
  );
}

class _PriceRegister extends StatelessWidget {
  const _PriceRegister({required this.products});
  final List<StoreCommodityPrice> products;
  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Current price register',
    subtitle: 'Latest selling prices compared with published SRP.',
    child: products.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('No commodity prices recorded yet.')),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TableRow(
                header: true,
                name: 'Commodity',
                price: 'Current',
                srp: 'SRP',
                status: 'Status',
              ),
              const Divider(height: 1),
              for (final product in products.take(10)) ...[
                _TableRow(
                  name: product.commodityName,
                  price: AppFormatters.currency(product.latestPrice),
                  srp: AppFormatters.currency(product.srp),
                  status: product.latestPrice > product.srp
                      ? 'Above SRP'
                      : 'Within SRP',
                  warning: product.latestPrice > product.srp,
                ),
                const Divider(height: 1),
              ],
            ],
          ),
  );
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.name,
    required this.price,
    required this.srp,
    required this.status,
    this.header = false,
    this.warning = false,
  });
  final String name;
  final String price;
  final String srp;
  final String status;
  final bool header;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w800 : FontWeight.w600,
      color: header ? AppColors.textSecondaryFor(context) : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620 && !header) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: style.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    Text('Current $price', style: style),
                    Text('SRP $srp', style: style),
                    Text(
                      status,
                      style: style.copyWith(
                        color: warning
                            ? const Color(0xFFFB7185)
                            : const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        if (constraints.maxWidth < 620 && header) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              Expanded(flex: 2, child: Text(price, style: style)),
              Expanded(flex: 2, child: Text(srp, style: style)),
              Expanded(
                flex: 2,
                child: Text(
                  status,
                  style: style.copyWith(
                    color: header
                        ? style.color
                        : warning
                        ? const Color(0xFFFB7185)
                        : const Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}
