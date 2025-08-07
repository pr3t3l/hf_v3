// hf_v3/lib/features/family_structure/presentation/pages/family_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
// Removed direct imports for Family, FamilyMember, UnregisteredMember as they are accessed via family object
import 'package:hf_v3/features/family_structure/presentation/pages/invite_member_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/manage_roles_screen.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart'; // Needed for currentUserId

class FamilyDetailsScreen extends ConsumerWidget {
  final String familyId;
  const FamilyDetailsScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;

    String getRoleTranslation(String role) {
      switch (role) {
        case 'parent':
          return appLocalizations.role_parent;
        case 'child':
          return appLocalizations.role_child;
        case 'guardian':
          return appLocalizations.role_guardian;
        case 'administrator':
          return appLocalizations.role_administrator;
        default:
          return role; // Fallback
      }
    }

    String getRelationshipTranslation(String type) {
      switch (type) {
        case 'sibling':
          return appLocalizations.relationship_sibling;
        case 'spouse':
          return appLocalizations.relationship_spouse;
        case 'cousin':
          return appLocalizations.relationship_cousin;
        case 'grandparent':
          return appLocalizations.relationship_grandparent;
        case 'other':
          return appLocalizations.relationship_other;
        case 'pet':
          return appLocalizations.relationship_pet;
        case 'deceased':
          return appLocalizations.relationship_deceased;
        default:
          return type;
      }
    }

    // Stream a single family's details
    final familyAsyncValue = ref
        .watch(familyServiceProvider)
        .getFamilyStream(familyId);
    final currentUserId = ref.watch(familyServiceProvider).currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.familyDetailsTitle),
        actions: [
          // TODO: Implement "Leave Family" button if desired
          // IconButton(
          //   icon: const Icon(Icons.exit_to_app),
          //   onPressed: () {
          //     // Logic to leave family
          //   },
          // ),
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
                // Registered Members List
                ListView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling for nested list
                  itemCount: family.memberUserIds.length,
                  itemBuilder: (context, index) {
                    final member = family.memberUserIds[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(member.displayName),
                        subtitle: Text(
                          getRoleTranslation(member.role),
                        ), // Corrected to use method
                        trailing:
                            isAdmin &&
                                member.userId !=
                                    currentUserId // Admins can manage others
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // Navigate to ManageRolesScreen for this member
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ManageRolesScreen(
                                        familyId: family.familyId,
                                        memberUserId: member.userId,
                                        currentRole: member.role,
                                        memberDisplayName: member
                                            .displayName, // Pass display name
                                      ),
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
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
                if (isAdmin) // Admin actions
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
                      // TODO: Implement Family Tree View (Future Vision)
                      // ElevatedButton(
                      //   onPressed: () {
                      //     // Navigate to Family Tree Screen
                      //   },
                      //   child: Text(appLocalizations.viewFamilyTreeButton),
                      // ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
