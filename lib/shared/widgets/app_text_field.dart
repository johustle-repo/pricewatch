import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.prefixText,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final IconData? prefixIcon;
  final String? prefixText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPasswordToggle = widget.obscureText;
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      maxLines: widget.maxLines,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixText != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    widget.prefixText!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : widget.prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 12, right: 4),
                child: Icon(
                  widget.prefixIcon,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: showPasswordToggle
            ? IconButton(
                tooltip: _obscureText ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }
}
