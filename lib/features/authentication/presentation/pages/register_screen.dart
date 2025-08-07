// hf_v3/lib/features/authentication/presentation/pages/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.passwordMismatch, // Corrected to use getter
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final authController = ref.read(authControllerProvider.notifier);
      try {
        await authController.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
        );
        // If registration is successful, pop back to login or navigate to home
        if (mounted) {
          // Guard against BuildContext across async gaps
          Navigator.of(context).pop(); // Go back to login screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.registrationSuccess, // Corrected to use getter
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ), // Use onPrimary for success messages
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary, // Use primary color for success
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        // Display error message to the user
        if (mounted) {
          // Guard against BuildContext across async gaps
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.registrationError(e.toString()), // Corrected to use method
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.registerTitle),
      ), // Corrected to use getter
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/logo_healthy_families.jpg', // Your logo path
                  height: 120, // Slightly smaller for registration screen
                  width: 120,
                ),
                const SizedBox(height: 24.0),

                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.firstNameLabel,
                  ), // Corrected to use getter
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations
                          .firstNameRequired; // Corrected to use getter
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.lastNameLabel,
                  ), // Corrected to use getter
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations
                          .lastNameRequired; // Corrected to use getter
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.emailLabel,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.emailRequired;
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return appLocalizations.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.passwordLabel,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.passwordRequired;
                    }
                    if (value.length < 8 ||
                        !value.contains(RegExp(r'[A-Z]')) ||
                        !value.contains(RegExp(r'[0-9]')) ||
                        !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                      return appLocalizations
                          .passwordWeak; // Corrected to use getter
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.confirmPasswordLabel,
                  ), // Corrected to use getter
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations
                          .confirmPasswordRequired; // Corrected to use getter
                    }
                    if (value != _passwordController.text) {
                      return appLocalizations
                          .passwordMismatch; // Corrected to use getter
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                authState.isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : ElevatedButton(
                        onPressed: _register,
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: Text(appLocalizations.registerButton),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
