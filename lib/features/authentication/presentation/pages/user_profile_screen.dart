// hf_v3/lib/features/authentication/presentation/pages/user_profile_screen.dart

import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Contenido del perfil del usuario'),
      ),
    );
  }
}
