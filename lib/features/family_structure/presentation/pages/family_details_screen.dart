// hf_v3/lib/features/family_structure/presentation/pages/family_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/invite_member_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/manage_roles_screen.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart'; // Needed for currentUserId
import 'package:hf_v3/features/family_structure/presentation/pages/family_tree_screen.dart';

class FamilyDetailsScreen extends ConsumerWidget {
  final String familyId;
  const FamilyDetailsScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;

    String getRoleTranslation(String role) {
      final translation = appLocalizations.roleLabel(role);
      return translation.isNotEmpty ? translation : role;
    }

    String getRelationshipTranslation(String type) {
      final translation = appLocalizations.relationshipLabel(type);
      return translation.isNotEmpty ? translation : type;
    }

    // Access FamilyService once for stream and current user ID
    final familyService = ref.watch(familyServiceProvider);
    // Stream a single family's details
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
            SnackBar(
              content: Text(appLocalizations.leaveFamilySuccess),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appLocalizations.leaveFamilyError(e),
              ),
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
      body: StreamBuilder(
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
                ), // Corrected to use method
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
                // Registered Members List (Refactored with StreamBuilder)
                StreamBuilder<List<FamilyMember>>(
                  stream: familyService.getFamilyMembersStream(familyId),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (memberSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${memberSnapshot.error}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    }
                    if (!memberSnapshot.hasData ||
                        memberSnapshot.data!.isEmpty) {
                      return Center(
                        child: Text(appLocalizations.noRegisteredMembers),
                      );
                    }

                    final members = memberSnapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(member.displayName),
                            subtitle: Text(getRoleTranslation(member.role)),
                            trailing: isAdmin && member.userId != currentUserId
                                ? IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ManageRolesScreen(
                                            familyId: family.familyId,
                                            memberUserId: member.userId,
                                            // The member object from the stream now has all the info
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
                          future: familyService.getUserDisplayName(pendingUid),
                          builder: (context, snapshot) {
                            final displayName =
                                snapshot.data ?? pendingUid;
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
                        ), // Corrected to use method
                        trailing: isAdmin
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  // Confirm deletion
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
                                      ), // Corrected to use method
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
                                      // Guard against BuildContext across async gaps
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
                                            ), // Corrected to use method
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
