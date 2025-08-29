import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart' as family_model;
import 'package:hf_v3/features/family_structure/presentation/pages/family_details_screen.dart'; // For providers
import 'package:hf_v3/l10n/app_localizations.dart';

class FamilyTreeScreen extends ConsumerWidget {
  final family_model.Family family;
  const FamilyTreeScreen({super.key, required this.family});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsyncValue = ref.watch(familyMembersStreamProvider(family.familyId));
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.viewFamilyTreeButton)),
      body: membersAsyncValue.when(
        data: (members) {
          final roles = {
            'administrator': <String>[],
            'parent': <String>[],
            'guardian': <String>[],
            'child': <String>[],
          };
          for (var member in members) {
            roles[member.role]?.add(member.displayName);
          }
          final unregistered = family.unregisteredMembers
              .map((m) => '${m.name} (${appLocalizations.relationshipLabel(m.relationship)})')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNode(context, family.familyName, isRoot: true),
                ...roles.entries.map((entry) {
                  return _buildSection(context, appLocalizations.roleLabel(entry.key), entry.value);
                }),
                _buildSection(context, appLocalizations.unregisteredMembersTitle, unregistered),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNode(BuildContext context, String text, {bool isRoot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isRoot ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontWeight: isRoot ? FontWeight.bold : FontWeight.normal)),
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
            children: names.map((name) => _buildNode(context, name)).toList(),
          ),
        ],
      ),
    );
  }
}
