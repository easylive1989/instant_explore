import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary/core/utils/validation_utils.dart';
import 'package:travel_diary/features/auth/services/auth_service.dart';
import 'package:travel_diary/shared/widgets/divider_with_text.dart';
import 'package:travel_diary/shared/widgets/password_field.dart';

/// 登入畫面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithGoogle();

      if (response != null && mounted) {
        // 登入成功，不需要手動導航，AuthStateListener 會處理
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

                  // App Name
                  Text(
                    'app.name'.tr(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'app.tagline'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Google Sign In Button
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
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

                  // Divider with "or"
                  DividerWithText(text: 'auth.or'.tr()),
                  const SizedBox(height: 24),

                  // Email Field
                  TextFormField(
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
                    controller: _passwordController,
                    labelText: 'auth.password'.tr(),
                    hintText: 'auth.passwordPlaceholder'.tr(),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'validation.required'.tr();
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _signInWithEmail(),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  if (!_isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'auth.login'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Link to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.noAccount'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const Key('login_register_button'),
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'auth.register'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Privacy Notice
                  Text(
                    'settings.terms'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
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
