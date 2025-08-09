// hf_v3/lib/features/family_structure/presentation/pages/family_tree_screen.dart

import 'package:flutter/material.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

class FamilyTreeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final parents = family.memberUserIds
        .where((m) => m.role == 'parent')
        .map((m) => m.displayName)
        .toList();
    final children = family.memberUserIds
        .where((m) => m.role == 'child')
        .map((m) => m.displayName)
        .toList();
    final guardians = family.memberUserIds
        .where((m) => m.role == 'guardian')
        .map((m) => m.displayName)
        .toList();
    final administrators = family.memberUserIds
        .where((m) => m.role == 'administrator')
        .map((m) => m.displayName)
        .toList();
    final unregistered = family.unregisteredMembers
        .map((m) =>
            '${m.name} (${_translateRelationship(context, m.relationship)})')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.viewFamilyTreeButton),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNode(family.familyName),
            _buildSection(context, appLocalizations.roleLabel('parent'), parents),
            _buildSection(context, appLocalizations.roleLabel('child'), children),
            _buildSection(
                context, appLocalizations.roleLabel('guardian'), guardians),
            _buildSection(context, appLocalizations.roleLabel('administrator'),
                administrators),
            _buildSection(context, appLocalizations.unregisteredMembersTitle, unregistered),
          ],
        ),
      ),
    );
  }
}
