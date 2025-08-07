// hf_v3/lib/features/family_structure/presentation/pages/family_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/create_family_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/join_family_screen.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/family_details_screen.dart'; // To navigate to family details
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
// import 'package:hf_v3/common/theme/app_theme.dart'; // Not directly needed here, theme is inherited

class FamilySelectionScreen extends ConsumerWidget {
  const FamilySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;
    final userFamiliesAsyncValue = ref.watch(userFamiliesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.familySelectionTitle),
        automaticallyImplyLeading:
            false, // Hide back button on this main screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section for creating or joining a family
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      appLocalizations.noFamilyMessage,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateFamilyScreen(),
                          ),
                        );
                      },
                      child: Text(appLocalizations.createFamilyButton),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      // Using OutlinedButton for secondary action
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const JoinFamilyScreen(),
                          ),
                        );
                      },
                      child: Text(appLocalizations.joinFamilyButton),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section for listing existing families
            Text(
              appLocalizations.yourFamiliesTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: userFamiliesAsyncValue.when(
                data: (families) {
                  if (families.isEmpty) {
                    return Center(
                      child: Text(
                        appLocalizations.noExistingFamilies,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: families.length,
                    itemBuilder: (context, index) {
                      final family = families[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: const Icon(
                            Icons.group,
                          ), // Using a generic group icon
                          title: Text(family.familyName),
                          subtitle: Text(
                            appLocalizations.familyMembersCount(
                              family.memberUserIds.length +
                                  family.unregisteredMembers.length,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onTap: () {
                            // Set this family as the active family
                            ref.read(activeFamilyProvider.notifier).state =
                                family;
                            // Navigate to FamilyDetailsScreen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FamilyDetailsScreen(
                                  familyId: family.familyId,
                                ),
                              ),
                            );
                          },
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
                    appLocalizations.errorLoadingFamilies(error.toString()),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
