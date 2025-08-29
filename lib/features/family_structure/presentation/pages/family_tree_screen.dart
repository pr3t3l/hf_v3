// hf_v3/lib/features/family_structure/presentation/pages/family_tree_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar ConsumerWidget
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as family_model;
import 'package:hf_v3/l10n/app_localizations.dart';
// Necesario para Firestore
import 'package:hf_v3/features/family_structure/services/family_service.dart'; // Importar FamilyService

class FamilyTreeScreen extends ConsumerWidget {
  // Cambiado a ConsumerWidget
  final family_model.Family family;
  const FamilyTreeScreen({super.key, required this.family});

  String _translateRelationship(BuildContext context, String type) {
    final appLocalizations = AppLocalizations.of(context)!;
    return appLocalizations.relationshipLabel(type);
  }

  Widget _buildNode(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> names) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: names.map(_buildNode).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Añadir WidgetRef ref
    final appLocalizations = AppLocalizations.of(context)!;
    final familyService = ref.watch(
      familyServiceProvider,
    ); // Obtener FamilyService

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.viewFamilyTreeButton)),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Lee de la subcolección 'members'
        stream: familyService.getFamilyMembersStream(family.familyId),
        builder: (context, memberSnapshot) {
          if (memberSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (memberSnapshot.hasError) {
            return Text(
              'Error loading members for tree: ${memberSnapshot.error}',
            );
          }
          if (!memberSnapshot.hasData || memberSnapshot.data!.isEmpty) {
            return const Text('No registered members for family tree.');
          }

          final registeredMembersData = memberSnapshot.data!;

          final parents = registeredMembersData
              .where((m) => m['role'] == 'parent')
              .map((m) => m['displayName'] as String)
              .toList();
          final children = registeredMembersData
              .where((m) => m['role'] == 'child')
              .map((m) => m['displayName'] as String)
              .toList();
          final guardians = registeredMembersData
              .where((m) => m['role'] == 'guardian')
              .map((m) => m['displayName'] as String)
              .toList();
          final administrators = registeredMembersData
              .where((m) => m['role'] == 'administrator')
              .map((m) => m['displayName'] as String)
              .toList();
          final unregistered = family.unregisteredMembers
              .map(
                (m) =>
                    '${m.name} (${_translateRelationship(context, m.relationship)})',
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNode(family.familyName),
                _buildSection(
                  context,
                  appLocalizations.roleLabel('parent'),
                  parents,
                ),
                _buildSection(
                  context,
                  appLocalizations.roleLabel('child'),
                  children,
                ),
                _buildSection(
                  context,
                  appLocalizations.roleLabel('guardian'),
                  guardians,
                ),
                _buildSection(
                  context,
                  appLocalizations.roleLabel('administrator'),
                  administrators,
                ),
                _buildSection(
                  context,
                  appLocalizations.unregisteredMembersTitle,
                  unregistered,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
