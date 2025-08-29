import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart' as family_model;
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

class FamilyTreeScreen extends ConsumerWidget {
  final String familyId;
  const FamilyTreeScreen({super.key, required this.familyId});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;
    final familyService = ref.watch(familyServiceProvider);
    final familyStream = familyService.getFamilyStream(familyId);
    final membersStream = familyService.getFamilyMembersStream(familyId);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.viewFamilyTreeButton),
      ),
      body: StreamBuilder<family_model.Family>(
        stream: familyStream,
        builder: (context, familySnapshot) {
          if (familySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (familySnapshot.hasError || !familySnapshot.hasData) {
            return Center(child: Text(appLocalizations.errorLoadingFamilyDetails('')));
          }
          final family = familySnapshot.data!;

          return StreamBuilder<List<FamilyMember>>(
            stream: membersStream,
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (memberSnapshot.hasError) {
                return Center(child: Text('Error: ${memberSnapshot.error}'));
              }
              final members = memberSnapshot.data ?? [];

              final parents = members
                  .where((m) => m.role == 'parent')
                  .map((m) => m.displayName)
                  .toList();
              final children = members
                  .where((m) => m.role == 'child')
                  .map((m) => m.displayName)
                  .toList();
              final guardians = members
                  .where((m) => m.role == 'guardian')
                  .map((m) => m.displayName)
                  .toList();
              final administrators = members
                  .where((m) => m.role == 'administrator')
                  .map((m) => m.displayName)
                  .toList();
              final unregistered = family.unregisteredMembers
                  .map((m) =>
                      '${m.name} (${_translateRelationship(context, m.relationship)})')
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNode(family.familyName),
                    _buildSection(context, appLocalizations.roleLabel('parent'), parents),
                    _buildSection(context, appLocalizations.roleLabel('child'), children),
                    _buildSection(context, appLocalizations.roleLabel('guardian'), guardians),
                    _buildSection(context, appLocalizations.roleLabel('administrator'), administrators),
                    _buildSection(context, appLocalizations.unregisteredMembersTitle, unregistered),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
