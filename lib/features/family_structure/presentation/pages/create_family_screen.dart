// hf_v3/lib/features/family_structure/presentation/pages/create_family_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';

class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _familyNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (_formKey.currentState!.validate()) {
      final familyController = ref.read(familyControllerProvider.notifier);
      try {
        // Llama al controlador para crear la familia y obtener su ID.
        final newFamilyId = await familyController.createFamily(
          _familyNameController.text.trim(),
        );

        if (mounted) {
          // Espera a que el stream de familias del usuario se actualice con la nueva familia.
          // Usamos .future para obtener la primera emisión después de la actualización.
          final families = await ref.read(userFamiliesStreamProvider.future);

          // Verifica si la nueva familia está presente en la lista actualizada.
          if (families.any((f) => f.familyId == newFamilyId)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.familyCreatedSuccess,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            // Navega de vuelta a la pantalla de selección de familia.
            if (!mounted) return;
            Navigator.of(context).pop();
          } else {
            // Si por alguna razón la familia no aparece en el stream después de un tiempo,
            // podríamos considerar esto un error o un problema de sincronización.
            throw Exception("Family created but not reflected in stream.");
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.familyCreatedError(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.createFamilyTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appLocalizations.createFamilyDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                TextFormField(
                  controller: _familyNameController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.familyNameLabel,
                    hintText: appLocalizations.familyNameHint,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.familyNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                familyState.isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : ElevatedButton(
                        onPressed: _createFamily,
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: Text(appLocalizations.createFamilyButton),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
