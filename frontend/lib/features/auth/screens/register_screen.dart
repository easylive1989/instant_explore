import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/core/utils/validation_utils.dart';
import 'package:context_app/features/auth/services/auth_service.dart';
import 'package:context_app/features/auth/widgets/divider_with_text.dart';
import 'package:context_app/features/auth/widgets/password_field.dart';

/// 註冊畫面
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Check if user is authenticated after signup
        if (response.user != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('auth.registerSuccess'.tr())));
          // User is now logged in, router will automatically redirect to home
          // The router's redirect logic will handle navigation to '/'
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'auth.registerFailed'.tr();

        // Handle specific error cases
        if (e.toString().contains('already registered') ||
            e.toString().contains('already exists')) {
          errorMessage = 'auth.emailAlreadyUsed'.tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle();

      if (response != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.loginSuccess'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'auth.loginFailed'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Icon(Icons.book, size: 100, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'auth.createAccount'.tr(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    key: const Key('register_email_field'),
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'auth.email'.tr(),
                      hintText: 'auth.emailPlaceholder'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final error = ValidationUtils.validateEmail(value);
                      return error?.tr();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  PasswordField(
                    key: const Key('register_password_field'),
                    controller: _passwordController,
                    labelText: 'auth.password'.tr(),
                    hintText: 'auth.passwordPlaceholder'.tr(),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final error = ValidationUtils.validatePassword(value);
                      return error?.tr();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  PasswordField(
                    key: const Key('register_confirm_password_field'),
                    controller: _confirmPasswordController,
                    labelText: 'auth.confirmPassword'.tr(),
                    hintText: 'auth.confirmPasswordPlaceholder'.tr(),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final error = ValidationUtils.validatePasswordConfirm(
                        value,
                        _passwordController.text,
                      );
                      return error?.tr();
                    },
                    onFieldSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('register_submit_button'),
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'auth.register'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Divider with "or"
                  DividerWithText(text: 'auth.or'.tr()),
                  const SizedBox(height: 24),

                  // Google Sign In Button
                  if (!_isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login, size: 24),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'auth.googleSignIn'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Link to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.haveAccount'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'auth.login'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
