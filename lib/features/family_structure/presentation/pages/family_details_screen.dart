import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart' as family_model;
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/invite_member_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/manage_roles_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/family_tree_screen.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

class FamilyDetailsScreen extends ConsumerWidget {
  final String familyId;
  const FamilyDetailsScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsyncValue = ref.watch(familyStreamProvider(familyId));
    final familyService = ref.watch(familyServiceProvider);
    final currentUserId = familyService.currentUserId;
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: familyAsyncValue.when(
          data: (family) => Text(family.familyName),
          loading: () => const Text(''),
          error: (_, __) => const Text(''),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _leaveFamily(context, ref, familyId, appLocalizations),
          ),
        ],
      ),
      body: familyAsyncValue.when(
        data: (family) {
          final isAdmin = family.adminUserIds.contains(currentUserId);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, appLocalizations.registeredMembersTitle),
                _buildMembersList(context, ref, familyId, isAdmin, currentUserId, appLocalizations),
                const SizedBox(height: 24),
                if (family.usersPending.isNotEmpty) ...[
                  _buildSectionTitle(context, appLocalizations.pendingMembersTitle),
                  _buildPendingList(familyService, family.usersPending, appLocalizations),
                  const SizedBox(height: 24),
                ],
                _buildSectionTitle(context, appLocalizations.unregisteredMembersTitle),
                _buildUnregisteredList(context, ref, family, isAdmin, appLocalizations),
                const SizedBox(height: 24),
                if (isAdmin)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InviteMemberScreen(familyId: family.familyId))),
                    child: Text(appLocalizations.inviteMemberButton),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FamilyTreeScreen(family: family))),
                  child: Text(appLocalizations.viewFamilyTreeButton),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _leaveFamily(BuildContext context, WidgetRef ref, String familyId, AppLocalizations localizations) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.confirmLeaveFamilyTitle),
        content: Text(localizations.confirmLeaveFamilyMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(localizations.cancelButton)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(localizations.leaveButton)),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(familyControllerProvider.notifier).leaveFamily(familyId);
        if (context.mounted) Navigator.of(context).pop();
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildMembersList(BuildContext context, WidgetRef ref, String familyId, bool isAdmin, String? currentUserId, AppLocalizations localizations) {
    final membersStream = ref.watch(familyMembersStreamProvider(familyId));
    return membersStream.when(
      data: (members) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(member.displayName),
              subtitle: Text(localizations.roleLabel(member.role)),
              trailing: isAdmin && member.userId != currentUserId
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageRolesScreen(familyId: familyId, memberUserId: member.userId))),
                    )
                  : null,
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildPendingList(FamilyService familyService, List<String> pendingUids, AppLocalizations localizations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingUids.length,
      itemBuilder: (context, index) {
        final pendingUid = pendingUids[index];
        return Card(
          child: FutureBuilder<String>(
            future: familyService.getUserDisplayName(pendingUid),
            builder: (context, snapshot) {
              return ListTile(
                leading: const Icon(Icons.hourglass_top),
                title: Text(snapshot.data ?? '...'),
                subtitle: Text(localizations.pendingMemberStatus),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUnregisteredList(BuildContext context, WidgetRef ref, family_model.Family family, bool isAdmin, AppLocalizations localizations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: family.unregisteredMembers.length,
      itemBuilder: (context, index) {
        final member = family.unregisteredMembers[index];
        return Card(
          child: ListTile(
            leading: Icon(member.isPet ? Icons.pets : Icons.person_outline),
            title: Text(member.name),
            subtitle: Text(localizations.relationshipLabel(member.relationship)),
            trailing: isAdmin
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await ref.read(familyControllerProvider.notifier).removeUnregisteredMember(family.familyId, member.memberId);
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

// Helper providers to avoid re-watching the same stream
final familyStreamProvider = StreamProvider.autoDispose.family<family_model.Family, String>((ref, familyId) {
  return ref.watch(familyServiceProvider).getFamilyStream(familyId);
});

final familyMembersStreamProvider = StreamProvider.autoDispose.family<List<FamilyMember>, String>((ref, familyId) {
  return ref.watch(familyServiceProvider).getFamilyMembersStream(familyId);
});
