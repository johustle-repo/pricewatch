import 'dart:math' as math;

import 'package:flutter/material.dart';

class AdaptiveStatGrid extends StatelessWidget {
  const AdaptiveStatGrid({
    super.key,
    required this.children,
    this.minTileWidth = 168,
    this.spacing = 12,
    this.maxColumns = 2,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawColumns =
            ((constraints.maxWidth + spacing) / (minTileWidth + spacing))
                .floor();
        final columnCount = math.max(1, math.min(maxColumns, rawColumns));
        final totalSpacing = spacing * (columnCount - 1);
        final tileWidth = (constraints.maxWidth - totalSpacing) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
