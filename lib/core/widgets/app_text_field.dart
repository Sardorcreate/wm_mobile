import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wm_mobile/core/theme/app_colors.dart';
import 'package:wm_mobile/core/theme/app_motion.dart';

/// The app's text input.
///
/// Consolidates the two divergent styles that existed before (the login page's
/// filled glass field and the profile page's outlined field) and adds a focus
/// state: the border brightens to the accent colour and the field picks up a
/// soft glow, so it's obvious which field is active on the dark gradient.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;

  /// When non-null, [onToggleObscure] renders the show/hide eye button.
  final bool obscure;
  final VoidCallback? onToggleObscure;

  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isPassword => widget.onToggleObscure != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _focused
              ? [AppColors.glass(0.20), AppColors.glass(0.10)]
              : [AppColors.glass(0.12), AppColors.glass(0.06)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _focused
              ? AppColors.accentGlow.withValues(alpha: 0.85)
              : AppColors.glassBorder,
          width: _focused ? 1.6 : 1.0,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscure,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15.5),
        cursorColor: AppColors.accentGlow,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: AppColors.textTertiary),
          prefixIcon: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Icon(
              widget.icon,
              key: ValueKey<bool>(_focused),
              color: _focused ? AppColors.accentGlow : AppColors.textSecondary,
              size: 21,
            ),
          ),
          suffixIcon: _isPassword
              ? IconButton(
                  onPressed: widget.onToggleObscure,
                  icon: Icon(
                    widget.obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.textSecondary,
                    size: 21,
                  ),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
