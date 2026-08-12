import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.caption,
    this.highlight = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = AppColors.borderFor(context);
    final muted = AppColors.isDark(context)
        ? AppColors.backgroundAltFor(context)
        : const Color(0xFFF1F5F9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 210;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 132 : 148),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: highlight
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.isDark(context)
                          ? const [Color(0xFF17213A), Color(0xFF0F172A)]
                          : const [Color(0xFF17213A), Color(0xFF24385B)],
                    )
                  : AppColors.surfaceGradientFor(context),
              borderRadius: BorderRadius.circular(compact ? 18 : 20),
              border: Border.all(
                color: highlight ? const Color(0xFF334A70) : border,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x160F172A),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: highlight ? Colors.white : null,
                          ),
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: highlight
                              ? Colors.white.withValues(alpha: .10)
                              : muted,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          icon,
                          color: highlight
                              ? const Color(0xFFFF8BA7)
                              : AppColors.primaryDark,
                          size: 21,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: highlight ? const Color(0xFFD5DEEC) : null,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      caption!,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: highlight
                            ? const Color(0xFFA8B5CB)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
