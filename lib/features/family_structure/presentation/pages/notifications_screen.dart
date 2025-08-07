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
      final familyService = ref.watch(
        familyServiceProvider,
      ); // Get the service instance
      return familyService.getPendingInvitationsStream(); // Use the new method
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
    final familyService = ref.read(
      familyServiceProvider,
    ); // Get FamilyService to fetch family names

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.notificationsTitle)),
      body: pendingInvitationsAsyncValue.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return Center(
              child: Text(
                appLocalizations.noPendingInvitations,
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
                        appLocalizations.invitationReceivedTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLocalizations.invitationFrom(
                          invitation.invitedByDisplayName,
                        ),
                      ),
                      // Fetch family name using FutureBuilder for better UX
                      FutureBuilder<String>(
                        future: familyService.getFamilyName(
                          invitation.familyId,
                        ), // New method to get family name
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              appLocalizations.invitationToFamily('...'),
                            ); // Placeholder while loading
                          } else if (snapshot.hasError) {
                            return Text(
                              appLocalizations.invitationToFamily('Error'),
                            );
                          } else {
                            return Text(
                              appLocalizations.invitationToFamily(
                                snapshot.data ?? 'Familia Desconocida',
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        appLocalizations.invitationExpires(
                          invitation.expiresAt
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                if (!context.mounted) return;
                                await familyService.declineInvitation(
                                  invitation.invitationId,
                                ); // Use new method
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        appLocalizations.invitationDeclined,
                                      ),
                                    ),
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
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(appLocalizations.declineButton),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              try {
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
                                    ),
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
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(appLocalizations.acceptButton),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                            ),
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
            appLocalizations.errorLoadingNotifications(error.toString()),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
//good