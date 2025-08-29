// hf_v3/lib/features/family_structure/presentation/pages/family_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/invite_member_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/manage_roles_screen.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/family_tree_screen.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as family_model; // Importar con alias

class FamilyDetailsScreen extends ConsumerWidget {
  final String familyId;
  const FamilyDetailsScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;

    String getRoleTranslation(String role) {
      return appLocalizations.roleLabel(role);
    }

    String getRelationshipTranslation(String type) {
      return appLocalizations.relationshipLabel(type);
    }

    final familyService = ref.watch(familyServiceProvider);
    final familyAsyncValue = familyService.getFamilyStream(familyId);
    final currentUserId = familyService.currentUserId;

    Future<void> handleLeaveFamily() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(appLocalizations.confirmLeaveFamilyTitle),
          content: Text(appLocalizations.confirmLeaveFamilyMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(appLocalizations.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(appLocalizations.leaveButton),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await ref.read(familyControllerProvider.notifier).leaveFamily(familyId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocalizations.leaveFamilySuccess)),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(appLocalizations.leaveFamilyError(e.toString())),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.familyDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: appLocalizations.leaveFamilyButton,
            onPressed: handleLeaveFamily,
          ),
        ],
      ),
      body: StreamBuilder<family_model.Family>(
        // Usar el alias family_model.Family
        stream: familyAsyncValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                appLocalizations.errorLoadingFamilyDetails(
                  snapshot.error.toString(),
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: Text(appLocalizations.noFamilyMessage));
          }
          final family = snapshot.data!;
          final isAdmin = family.adminUserIds.contains(currentUserId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  family.familyName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.registeredMembersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Registered Members List (Ahora lee de la subcolección 'members')
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: familyService.getFamilyMembersStream(family.familyId),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (memberSnapshot.hasError) {
                      return Text(
                        'Error loading members: ${memberSnapshot.error}',
                      );
                    }
                    if (!memberSnapshot.hasData ||
                        memberSnapshot.data!.isEmpty) {
                      return const Text('No registered members found.');
                    }

                    final registeredMembers = memberSnapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: registeredMembers.length,
                      itemBuilder: (context, index) {
                        final member = registeredMembers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(member['displayName']!),
                            subtitle: Text(getRoleTranslation(member['role']!)),
                            trailing:
                                isAdmin && member['userId'] != currentUserId
                                ? IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ManageRolesScreen(
                                            familyId: family.familyId,
                                            memberUserId: member['userId']!,
                                            // Ya no es necesario pasar currentRole y memberDisplayName
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
                // Pending Members Section
                if (family.usersPending.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    appLocalizations.pendingMembersTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: family.usersPending.length,
                    itemBuilder: (context, index) {
                      final pendingUid = family.usersPending[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: FutureBuilder<String>(
                          // Pasa el familyId para que getUserDisplayName pueda buscar en la subcolección
                          future: familyService.getUserDisplayName(
                            pendingUid,
                            familyId: family.familyId,
                          ),
                          builder: (context, snapshot) {
                            final displayName = snapshot.data ?? pendingUid;
                            return ListTile(
                              leading: const Icon(Icons.hourglass_top),
                              title: Text(displayName),
                              subtitle: Text(
                                appLocalizations.pendingMemberStatus,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  appLocalizations.unregisteredMembersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                // Unregistered Members List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: family.unregisteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = family.unregisteredMembers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: member.isPet
                            ? const Icon(Icons.pets)
                            : (member.isDeceased
                                  ? const Icon(Icons.sentiment_dissatisfied)
                                  : const Icon(Icons.person_outline)),
                        title: Text(member.name),
                        subtitle: Text(
                          getRelationshipTranslation(member.relationship),
                        ),
                        trailing: isAdmin
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        appLocalizations.confirmDeleteTitle,
                                      ),
                                      content: Text(
                                        appLocalizations
                                            .confirmDeleteUnregisteredMember(
                                              member.name,
                                            ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: Text(
                                            appLocalizations.cancelButton,
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: Text(
                                            appLocalizations.deleteButton,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      if (!context.mounted) return;
                                      await ref
                                          .read(
                                            familyControllerProvider.notifier,
                                          )
                                          .removeUnregisteredMember(
                                            family.familyId,
                                            member.memberId,
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              appLocalizations
                                                  .memberRemovedSuccess,
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              appLocalizations
                                                  .memberRemovedError(
                                                    e.toString(),
                                                  ),
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (isAdmin)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  InviteMemberScreen(familyId: family.familyId),
                            ),
                          );
                        },
                        child: Text(appLocalizations.inviteMemberButton),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FamilyTreeScreen(family: family),
                            ),
                          );
                        },
                        child: Text(appLocalizations.viewFamilyTreeButton),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: handleLeaveFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  icon: const Icon(Icons.exit_to_app),
                  label: Text(appLocalizations.leaveFamilyButton),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
