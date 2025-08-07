// hf_v3/lib/features/family_structure/presentation/pages/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/data/models/invitation.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart'; // Import FamilyService

// Provider to stream pending invitations for the current user
final pendingInvitationsStreamProvider =
    StreamProvider.autoDispose<List<Invitation>>((ref) {
  return ref.watch(familyServiceProvider).getPendingInvitationsStream();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;
    final pendingInvitationsAsyncValue = ref.watch(
      pendingInvitationsStreamProvider,
    );
    final familyController = ref.read(familyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocalizations.notificationsTitle,
        ), // Corrected to use getter
      ),
      body: pendingInvitationsAsyncValue.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Text(
                appLocalizations
                    .noPendingInvitations, // Corrected to use getter
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations
                            .invitationReceivedTitle, // Corrected to use getter
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLocalizations.invitationFrom(
                          invitation.invitedByDisplayName,
                        ),
                      ), // Corrected to use method
                      Text(
                        appLocalizations.invitationToFamily(
                          invitation.familyId,
                        ),
                      ), // TODO: Fetch family name for better UX // Corrected to use method
                      Text(
                        appLocalizations.invitationExpires(
                          invitation.expiresAt
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                        ),
                      ), // Corrected to use method
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              // Logic to decline invitation (update status in Firestore)
                              try {
                                // Guard against BuildContext across async gaps
                                if (!context.mounted) return;
                                await ref
                                    .read(familyServiceProvider)
                                    .declineInvitation(invitation.invitationId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appLocalizations.invitationDeclined,
                                      ),
                                    ), // Corrected to use getter
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appLocalizations.invitationDeclineError(
                                          e.toString(),
                                        ),
                                      ),
                                    ), // Corrected to use method
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            child: Text(
                              appLocalizations.declineButton,
                            ), // Corrected to use getter
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // Logic to accept invitation (call familyController.joinFamily)
                              try {
                                // Guard against BuildContext across async gaps
                                if (!context.mounted) return;
                                await familyController.joinFamily(
                                  invitation.invitationCode,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appLocalizations.invitationAccepted,
                                      ),
                                    ), // Corrected to use getter
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appLocalizations.invitationAcceptError(
                                          e.toString(),
                                        ),
                                      ),
                                    ), // Corrected to use method
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                            ),
                            child: Text(
                              appLocalizations.acceptButton,
                            ), // Corrected to use getter
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            appLocalizations.errorLoadingNotifications(
              error.toString(),
            ), // Corrected to use method
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
