import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.showClearButton = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showClearButton;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    final radius = BorderRadius.circular(compact ? 18 : 20);
    final background = AppColors.surfaceFor(
      context,
    ).withValues(alpha: AppColors.isDark(context) ? 0.94 : 0.92);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasValue = value.text.trim().isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide.none,
              ),
              hintText: hintText,
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 18,
                vertical: compact ? 14 : 16,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: compact ? 42 : 48,
                minHeight: compact ? 42 : 48,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: showClearButton && hasValue
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
