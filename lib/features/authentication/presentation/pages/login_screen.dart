// hf_v3/lib/features/authentication/presentation/pages/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

// Correct imports for the screens
import 'package:hf_v3/features/authentication/presentation/pages/register_screen.dart';
import 'package:hf_v3/features/authentication/presentation/pages/forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final authController = ref.read(authControllerProvider.notifier);
      try {
        await authController.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } catch (e) {
        if (mounted) {
          // Display error message to the user using SnackBar with theme colors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.loginError(e.toString()),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ), // Text color on error background
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.error, // Error background color
              behavior:
                  SnackBarBehavior.floating, // Makes it float above content
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ), // Rounded corners
              margin: const EdgeInsets.all(16), // Margin from edges
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
      appBar: AppBar(title: Text(appLocalizations.loginTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            24.0,
          ), // Increased padding for more white space
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/logo.jpg', // Your logo path
                  height: 150, // Adjusted height for prominence
                  width: 150,
                ),
                const SizedBox(height: 32.0), // Increased spacing

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.emailLabel,
                    hintText: appLocalizations.emailLabel, // Added hint text
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
                    hintText: appLocalizations.passwordLabel, // Added hint text
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.passwordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                authState.isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ) // Use theme color
                    : ElevatedButton(
                        onPressed: _signIn,
                        style: Theme.of(
                          context,
                        ).elevatedButtonTheme.style, // Apply theme style
                        child: Text(appLocalizations.loginButton),
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ForgotPasswordScreen(), // Ensure this class is correctly defined in its file
                      ),
                    );
                  },
                  style: Theme.of(
                    context,
                  ).textButtonTheme.style, // Apply theme style
                  child: Text(appLocalizations.forgotPasswordButton),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const RegisterScreen(), // Ensure this class is correctly defined in its file
                      ),
                    );
                  },
                  style: Theme.of(
                    context,
                  ).textButtonTheme.style, // Apply theme style
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
