import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Password input field with visibility toggle
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Color? fillColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefixIcon;

  const PasswordField({
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.prefixIcon,
    super.key,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are using the new custom styling
    final bool hasCustomStyling = widget.fillColor != null;
    final double radius = widget.borderRadius ?? 12.0;
    const primaryColor = Color(0xFF137FEC);

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      style: hasCustomStyling ? const TextStyle(color: Colors.white) : null,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: hasCustomStyling
            ? TextStyle(color: Colors.white.withValues(alpha: 0.4))
            : null,
        filled: hasCustomStyling,
        fillColor: widget.fillColor,
        contentPadding: widget.contentPadding,
        prefixIcon: widget.prefixIcon,
        border: hasCustomStyling
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              )
            : const OutlineInputBorder(),
        enabledBorder: hasCustomStyling
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              )
            : null,
        focusedBorder: hasCustomStyling
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: primaryColor),
              )
            : null,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: hasCustomStyling ? Colors.white54 : null,
          ),
          onPressed: _togglePasswordVisibility,
          tooltip: _obscureText
              ? 'auth.show_password'.tr()
              : 'auth.hide_password'.tr(),
        ),
      ),
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
