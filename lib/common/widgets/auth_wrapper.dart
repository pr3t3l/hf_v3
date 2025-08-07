// hf_v3/lib/common/widgets/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/presentation/pages/login_screen.dart';
import 'package:hf_v3/features/authentication/presentation/pages/home_screen.dart'; // Ensure correct path
import 'package:hf_v3/providers/auth_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, navigate to HomeScreen
          return const HomeScreen();
        } else {
          // User is not authenticated, navigate to LoginScreen
          return const LoginScreen();
        }
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // Use theme background color
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(
              context,
            ).colorScheme.primary, // Use theme primary color
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ), // Use theme error color
          ),
        ),
      ),
    );
  }
}
