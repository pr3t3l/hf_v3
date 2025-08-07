// hf_v3/lib/features/family_structure/presentation/widgets/family_switcher_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as family_model; // Alias for your Family model

class FamilySwitcherWidget extends ConsumerWidget {
  const FamilySwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = AppLocalizations.of(context)!;
    final userFamiliesAsyncValue = ref.watch(userFamiliesStreamProvider);
    final activeFamily = ref.watch(activeFamilyProvider);

    return userFamiliesAsyncValue.when(
      data: (families) {
        if (families.isEmpty) {
          return Text(
            appLocalizations.noFamilySelected, // Corrected to use getter
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor,
            ), // Ensure text color is visible
          );
        }

        // Find the currently active family in the list
        // If activeFamily is null or not in the list, default to the first family
        final currentActiveFamily = activeFamily ?? families.first;

        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentActiveFamily.familyId,
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                final selected = families.firstWhere(
                  (f) => f.familyId == newValue,
                );
                ref.read(activeFamilyProvider.notifier).state = selected;
                // Optionally, navigate to FamilyDetailsScreen if not already there or refresh content
                // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => FamilyDetailsScreen(familyId: selected.familyId)));
              }
            },
            items: families.map<DropdownMenuItem<String>>((
              family_model.Family family,
            ) {
              // Use alias here
              return DropdownMenuItem<String>(
                value: family.familyId,
                child: Text(family.familyName),
              );
            }).toList(),
          ),
        );
      },
      loading: () => CircularProgressIndicator(
        color: Theme.of(context).appBarTheme.foregroundColor,
      ),
      error: (error, stack) => Text(
        appLocalizations.errorLoadingFamiliesShort, // Corrected to use getter
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
