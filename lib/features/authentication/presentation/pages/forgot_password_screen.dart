// hf_v3/lib/features/authentication/presentation/pages/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      final authController = ref.read(authControllerProvider.notifier);
      try {
        await authController.resetPassword(_emailController.text.trim());
        if (mounted) {
          // Guard against BuildContext across async gaps
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.passwordResetEmailSent, // Corrected to use getter
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
          Navigator.of(context).pop(); // Go back to login screen
        }
      } catch (e) {
        if (mounted) {
          // Guard against BuildContext across async gaps
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.passwordResetError(e.toString()), // Corrected to use method
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
        title: Text(appLocalizations.forgotPasswordTitle),
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
                  height: 120, // Consistent size
                  width: 120,
                ),
                const SizedBox(height: 24.0),

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
                const SizedBox(height: 24.0),
                authState.isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : ElevatedButton(
                        onPressed: _sendResetEmail,
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: Text(
                          appLocalizations.sendResetLinkButton,
                        ), // Corrected to use getter
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
