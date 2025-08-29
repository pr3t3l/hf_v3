// hf_v3/lib/features/family_structure/presentation/pages/family_tree_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart';
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

class FamilyTreeScreen extends ConsumerWidget {
  final Family family;
  const FamilyTreeScreen({super.key, required this.family});

  String _translateRelationship(BuildContext context, String type) {
    final appLocalizations = AppLocalizations.of(context)!;
    final translation = appLocalizations.relationshipLabel(type);
    return translation.isNotEmpty ? translation : type;
  }

  Widget _buildNode(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;
    final familyService = ref.watch(familyServiceProvider);
    final unregistered = family.unregisteredMembers
        .map((m) =>
            '${m.name} (${_translateRelationship(context, m.relationship)})')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.viewFamilyTreeButton),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<FamilyMember>>(
        stream: familyService.getFamilyMembersStream(family.familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(appLocalizations.noRegisteredMembers));
          }

          final members = snapshot.data!;
          final parents = members
              .where((m) => m.role == 'parent')
              .map((m) => _buildNode(m.displayName))
              .toList();
          final children = members
              .where((m) => m.role == 'child')
              .map((m) => _buildNode(m.displayName))
              .toList();
          final guardians = members
              .where((m) => m.role == 'guardian')
              .map((m) => _buildNode(m.displayName))
              .toList();
          final administrators = members
              .where((m) => m.role == 'administrator')
              .map((m) => _buildNode(m.displayName))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNode(family.familyName),
                _buildSection(
                    context, appLocalizations.roleLabel('parent'), parents),
                _buildSection(
                    context, appLocalizations.roleLabel('child'), children),
                _buildSection(context, appLocalizations.roleLabel('guardian'),
                    guardians),
                _buildSection(
                    context,
                    appLocalizations.roleLabel('administrator'),
                    administrators),
                _buildSection(
                  context,
                  appLocalizations.unregisteredMembersTitle,
                  unregistered.map(_buildNode).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
