import 'package:flutter/material.dart';

/// Password input field with visibility toggle
///
/// A reusable password field component that provides:
/// - Password visibility toggle
/// - Form validation support
/// - Customizable labels and hints
/// - Consistent styling
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const PasswordField({
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
    this.onFieldSubmitted,
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
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: _togglePasswordVisibility,
          tooltip: _obscureText ? '顯示密碼' : '隱藏密碼',
        ),
      ),
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
