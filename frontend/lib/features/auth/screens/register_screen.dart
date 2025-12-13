import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:context_app/core/utils/validation_utils.dart';
import 'package:context_app/features/auth/presentation/controllers/register_controller.dart';
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

    await ref
        .read(registerControllerProvider.notifier)
        .registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(registerControllerProvider.notifier).registerWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    // Custom colors from design
    const backgroundColor = Color(0xFF101922);
    const surfaceColor = Color(0xFF1C2630);
    const primaryColor = Color(0xFF137FEC);

    ref.listen<AsyncValue<void>>(registerControllerProvider, (previous, next) {
      if (next.hasError) {
        if (mounted) {
          String errorMessage = 'auth.registerFailed'.tr();
          final error = next.error.toString();

          if (error.contains('already registered') ||
              error.contains('already exists')) {
            errorMessage = 'auth.emailAlreadyUsed'.tr();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (next is AsyncData && !next.isLoading) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('auth.registerSuccess'.tr())));
        }
      }
    });

    final state = ref.watch(registerControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container (Gradient)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.history_edu,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Account
                  Text(
                    'auth.createAccount'.tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'auth.createAccountSubtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    key: const Key('register_email_field'),
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail, color: Colors.white54),
                      hintText: 'auth.emailPlaceholder'.tr(),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primaryColor),
                      ),
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
                    hintText: 'auth.passwordPlaceholder'.tr(),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final error = ValidationUtils.validatePassword(value);
                      return error?.tr();
                    },
                    // Custom decoration
                    fillColor: surfaceColor,
                    borderRadius: 16.0,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  PasswordField(
                    key: const Key('register_confirm_password_field'),
                    controller: _confirmPasswordController,
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
                    // Custom decoration
                    fillColor: surfaceColor,
                    borderRadius: 16.0,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      key: const Key('register_submit_button'),
                      onPressed: isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.25),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'auth.register'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  DividerWithText(text: 'auth.or'.tr()),
                  const SizedBox(height: 32),

                  // Social Buttons
                  Column(
                    children: [
                      // Google
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _signInWithGoogle,
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.g_mobiledata, // Fallback icon
                                size: 24,
                                color: Colors.white,
                              );
                            },
                          ),
                          label: Text(
                            'auth.googleSignIn'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: surfaceColor,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Apple (Visual only)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed:
                              null, // Disabled as functionality not implemented
                          icon: const Icon(
                            Icons.apple,
                            size: 24,
                            color: Colors.black,
                          ),
                          label: Text(
                            'auth.appleSignIn'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.haveAccount'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'auth.login'.tr(),
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
