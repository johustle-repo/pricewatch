import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/market_prices.dart';

/// Header button that opens the PriceWatch guide.
class PriceWatchGuideButton extends StatelessWidget {
  const PriceWatchGuideButton({super.key, this.color});

  /// Icon color for use on colored headers; defaults to the app bar color.
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'PriceWatch guide',
    onPressed: () => showPriceWatchGuide(context),
    icon: Icon(Icons.help_outline_rounded, color: color),
  );
}

/// Opens the guide as a dialog on wide screens and a sheet on phones.
Future<void> showPriceWatchGuide(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 720) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 860,
            maxHeight: size.height * 0.86,
          ),
          child: const _GuideContent(),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        SizedBox(height: size.height * 0.88, child: const _GuideContent()),
  );
}

class _GuideContent extends StatelessWidget {
  const _GuideContent();

  static const _tabs = [
    (Icons.rocket_launch_outlined, 'Start'),
    (Icons.sell_outlined, 'Prices'),
    (Icons.shopping_basket_outlined, 'Commodities'),
    (Icons.table_chart_outlined, 'CSV'),
    (Icons.info_outline_rounded, 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: _tabs.length,
      child: ColoredBox(
        color: AppColors.surfaceFor(context),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.isDark(context)
                      ? const [AppColors.darkPrimaryDeep, AppColors.darkSurface]
                      : const [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PriceWatch guide',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Accounts, prices, commodities and CSV files',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      for (final (icon, label) in _tabs)
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 18),
                              const SizedBox(width: 6),
                              Text(label),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _StartTab(),
                  _PricesTab(),
                  _CommoditiesTab(),
                  _CsvTab(),
                  _AboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPage extends StatelessWidget {
  const _TabPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
    children: children,
  );
}

class _StartTab extends StatelessWidget {
  const _StartTab();

  @override
  Widget build(BuildContext context) => _TabPage(
    children: [
      const _SectionTitle(
        'Create a community account',
        'Anyone can register to track prices, keep a watchlist and send reports.',
      ),
      const _Step(
        number: 1,
        title: 'Open Create account',
        body: 'Choose Create account from the sign-in page.',
      ),
      const _Step(
        number: 2,
        title: 'Enter your name and email',
        body: 'Use an email you can open; password reset links are sent there.',
      ),
      _Step(
        number: 3,
        title: 'Choose a password',
        body: 'Type it twice to confirm. It needs:',
        extra: const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(Icons.straighten_rounded, '8+ characters'),
            _Pill(Icons.text_fields_rounded, '1 uppercase letter'),
            _Pill(Icons.pin_outlined, '1 number'),
          ],
        ),
      ),
      const _Step(
        number: 4,
        title: 'Submit',
        body: 'You are signed in as a community user right away.',
        isLast: true,
      ),
      const SizedBox(height: 8),
      const _Note(
        icon: Icons.storefront_outlined,
        text:
            'Vendor accounts are not self-registered. An administrator creates them after verifying the shop, and each vendor account manages one shop.',
      ),
    ],
  );
}

class _PricesTab extends StatelessWidget {
  const _PricesTab();

  @override
  Widget build(BuildContext context) => _TabPage(
    children: [
      const _SectionTitle(
        'Reading a price',
        'What the numbers and badges on each commodity mean.',
      ),
      _TopicGrid(
        children: [
          _Topic(
            icon: Icons.functions_rounded,
            title: 'Average across stores',
            body:
                'The price shown is the average of each store’s latest price. Stores whose latest price is more than '
                '${currentPriceWindow.inDays} days older than the newest record are left out.',
          ),
          const _Topic(
            icon: Icons.verified_outlined,
            title: 'SRP badges',
            body:
                'SRP is the suggested retail price. Above SRP, At SRP and Below SRP compare the average with it. Above SRP is a signal to review, not proof of a violation.',
          ),
          _Topic(
            icon: Icons.history_rounded,
            title: 'Stale prices',
            body:
                'A price is marked stale when its newest record is more than ${stalePriceAge.inDays} days old. Check with the vendor before relying on it.',
          ),
          const _Topic(
            icon: Icons.hourglass_empty_rounded,
            title: 'No price yet',
            body:
                'No store has recorded a price for the item. The SRP is shown only for reference.',
          ),
          const _Topic(
            icon: Icons.account_tree_outlined,
            title: 'Sub-categories',
            body:
                'Items are grouped inside each category, such as Tilapia, Galunggong and Bangus under Fish. Each group shows its price range and average.',
          ),
          const _Topic(
            icon: Icons.trending_up_rounded,
            title: 'Price changes',
            body:
                'Increases compare a store with its own earlier price, never one store with another, so different vendors are not mistaken for a price change.',
          ),
        ],
      ),
    ],
  );
}

class _CommoditiesTab extends StatelessWidget {
  const _CommoditiesTab();

  @override
  Widget build(BuildContext context) => const _TabPage(
    children: [
      _SectionTitle(
        'What PriceWatch monitors',
        'Basic market goods sold by weight, piece or standard pack.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(Icons.rice_bowl_outlined, 'Rice'),
          _Pill(Icons.egg_outlined, 'Eggs'),
          _Pill(Icons.set_meal_outlined, 'Fish'),
          _Pill(Icons.kebab_dining_outlined, 'Meat'),
          _Pill(Icons.eco_outlined, 'Vegetables'),
        ],
      ),
      SizedBox(height: 20),
      _TopicGrid(
        children: [
          _Topic(
            icon: Icons.check_circle_outline_rounded,
            title: 'Commodities',
            body:
                'Interchangeable goods where the same product and unit can be compared across stores, such as a kilogram of well-milled rice.',
          ),
          _Topic(
            icon: Icons.block_rounded,
            title: 'Not monitored',
            body:
                'Services and differentiated finished products, such as branded or prepared goods, are outside the market-price scope.',
          ),
          _Topic(
            icon: Icons.scale_outlined,
            title: 'Compare like with like',
            body:
                'Always compare the same product, size and unit. A 25 kg rice bag is tracked separately from rice sold per kilogram.',
          ),
        ],
      ),
    ],
  );
}

class _CsvTab extends StatelessWidget {
  const _CsvTab();

  @override
  Widget build(BuildContext context) => const _TabPage(
    children: [
      _SectionTitle(
        'What is a CSV file?',
        'Comma-Separated Values: a table saved as plain text. Excel and Google Sheets open it directly.',
      ),
      _CsvExample(),
      SizedBox(height: 16),
      _TopicGrid(
        children: [
          _Topic(
            icon: Icons.view_headline_rounded,
            title: 'First row: column names',
            body:
                'Every row after it is one record. For prices use Commodity, PriceList and StoreName.',
          ),
          _Topic(
            icon: Icons.upload_file_rounded,
            title: 'Importing',
            body:
                'Administrators import price and store lists. Rows are checked first, and invalid rows are skipped and listed in an error report.',
          ),
          _Topic(
            icon: Icons.history_toggle_off_rounded,
            title: 'Keeping history',
            body:
                'Choose Record as a new price to keep earlier prices for trends. Replace deletes the store’s earlier prices for that item.',
          ),
        ],
      ),
    ],
  );
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) => const _TabPage(
    children: [
      _SectionTitle(
        'About PriceWatch',
        'Commodity price monitoring for Lingayen markets.',
      ),
      _TopicGrid(
        children: [
          _Topic(
            icon: Icons.groups_outlined,
            title: 'Who uses it',
            body:
                'The public views the market price board, community users track and report prices, vendors keep their shop prices current, and administrators manage the data.',
          ),
          _Topic(
            icon: Icons.code_rounded,
            title: 'How it is built',
            body:
                'A Flutter app written in Dart, with data stored in Firebase. Prices update for everyone as soon as they are saved.',
          ),
        ],
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.extra,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String body;
  final Widget? extra;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.borderFor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      height: 1.5,
                    ),
                  ),
                  if (extra != null) ...[const SizedBox(height: 10), extra!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 600
          ? (constraints.maxWidth - 14) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _Topic extends StatelessWidget {
  const _Topic({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundAltFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderFor(context).withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    height: 1.55,
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

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.info.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.readableFor(context, AppColors.info),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.55),
          ),
        ),
      ],
    ),
  );
}

class _CsvExample extends StatelessWidget {
  const _CsvExample();

  static const _rows = [
    ['Commodity', 'PriceList', 'StoreName'],
    ['Tilapia', '140.00', 'Sample Stall 01'],
    ['Bangus (Large)', '230.00', 'Sample Stall 01'],
    ['Premium Rice', '56.00', 'Sample Stall 02'],
  ];

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderFor(context);
    final mono = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.5);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.backgroundAltFor(context),
            child: Text(
              _rows.map((row) => row.join(',')).join('\n'),
              style: mono,
            ),
          ),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: border),
              top: BorderSide(color: border),
            ),
            children: [
              for (var i = 0; i < _rows.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.surfaceMutedFor(context) : null,
                  ),
                  children: [
                    for (final cell in _rows[i])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          cell,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
