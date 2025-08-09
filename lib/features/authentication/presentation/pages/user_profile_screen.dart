// hf_v3/lib/features/authentication/presentation/pages/user_profile_screen.dart


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hf_v3/features/authentication/presentation/pages/forgot_password_screen.dart';


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),

      body: user == null
          ? const Center(child: Text('No hay usuario autenticado'))
          : FutureBuilder<
              DocumentSnapshot<Map<String, dynamic>>>
              (
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('Perfil de usuario no disponible'),
                  );
                }

                final data = snapshot.data!.data()!;
                final firstName = data['firstName'] ?? '';
                final lastName = data['lastName'] ?? '';
                final email = data['email'] ?? user.email ?? '';
                final language = data['preferredLanguage'] ?? 'es';

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      title: const Text('Nombre y Apellidos'),
                      subtitle: Text('$firstName $lastName'),
                    ),
                    ListTile(
                      title: const Text('Correo Electrónico'),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      title: const Text('Idioma por Defecto'),
                      subtitle: Text(language),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('Modificar contraseña'),
                    ),
                  ],
                );
              },
            ),

    );
  }
}
