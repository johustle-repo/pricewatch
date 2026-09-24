import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PriceWatchHelp extends StatelessWidget {
  const PriceWatchHelp({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Material(
      color: AppColors.surfaceFor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderFor(context)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        iconColor: AppColors.textSecondaryFor(context),
        collapsedIconColor: AppColors.textSecondaryFor(context),
        leading: Icon(
          Icons.help_outline_rounded,
          color: AppColors.textSecondaryFor(context),
        ),
        title: Text(
          'PriceWatch guide',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Account setup, market terms, and file imports',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _GuideTopic(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'How to create an account',
                      description:
                          'Open Create account from the login page. Enter your full name and email, then create and confirm a password. Use at least 8 characters, one uppercase letter, and one number. Submit the form to register as a community user. Vendor accounts are created by an administrator after shop verification.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _GuideTopic(
                      icon: Icons.table_chart_outlined,
                      title: 'What is a CSV file?',
                      description:
                          'CSV means Comma-Separated Values. It stores a table as plain text: the first row contains column names and each following row contains a record. You can open it in Excel. PriceWatch imports store and price records and exports reports using CSV.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _GuideTopic(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Commodities and non-commodities',
                      description:
                          'PriceWatch focuses on market goods such as rice, fish, meat, and vegetables. These are the commodities monitored here. Non-commodities, such as services and differentiated finished products, are outside this market-price monitoring scope. Compare prices using the same product and unit.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _GuideTopic(
                      icon: Icons.info_outline,
                      title: 'About PriceWatch',
                      description:
                          'The application is written in Dart using Flutter. Firebase Cloud Functions use JavaScript.',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _GuideTopic extends StatelessWidget {
  const _GuideTopic({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.backgroundAltFor(context),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondaryFor(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

class VendorDocumentLegend extends StatelessWidget {
  const VendorDocumentLegend({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendor document legend',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DocumentLabel(
              label: 'Business permit',
              icon: Icons.description_outlined,
              color: Color(0xFFDC2626),
              darkColor: Color(0xFFFCA5A5),
            ),
            _DocumentLabel(
              label: 'Ticket',
              icon: Icons.confirmation_number_outlined,
              color: Color(0xFF047857),
              darkColor: Color(0xFF6EE7B7),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Document types only. Verification status is not shown here.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

class _DocumentLabel extends StatelessWidget {
  const _DocumentLabel({
    required this.label,
    required this.icon,
    required this.color,
    required this.darkColor,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color darkColor;

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.isDark(context) ? darkColor : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.09),
        border: Border.all(color: foreground.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
