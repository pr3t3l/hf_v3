import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

// Provider to fetch a single family member's details
final familyMemberProvider = StreamProvider.autoDispose
    .family<FamilyMember, ({String familyId, String memberId})>((ref, ids) {
  final familyService = ref.watch(familyServiceProvider);
  return familyService.getFamilyMemberStream(ids.familyId, ids.memberId);
});

class ManageRolesScreen extends ConsumerStatefulWidget {
  final String familyId;
  final String memberUserId;

  const ManageRolesScreen({
    super.key,
    required this.familyId,
    required this.memberUserId,
  });

  @override
  ConsumerState<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends ConsumerState<ManageRolesScreen> {
  String? _selectedRole;
  final List<String> _availableRoles = [
    'parent',
    'child',
    'guardian',
    'administrator',
  ];

  // No initState needed to set role, it will be set by the stream

  String _getRoleTranslation(String role, AppLocalizations localizations) {
    final translation = localizations.roleLabel(role);
    return translation.isNotEmpty ? translation : role;
  }

  Future<void> _updateRole(String currentRole) async {
    if (_selectedRole == null || _selectedRole == currentRole) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final familyController = ref.read(familyControllerProvider.notifier);
    try {
      await familyController.updateMemberRole(
        widget.familyId,
        widget.memberUserId,
        _selectedRole!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.roleUpdatedSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.roleUpdatedError(e.toString()),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final memberAsyncValue = ref.watch(familyMemberProvider(
        (familyId: widget.familyId, memberId: widget.memberUserId)));

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.manageRolesTitle)),
      body: memberAsyncValue.when(
        data: (member) {
          // Initialize _selectedRole inside the build method if it's null
          _selectedRole ??= member.role;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appLocalizations.manageRoleFor(member.displayName),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    appLocalizations.currentRoleLabel(
                      _getRoleTranslation(member.role, appLocalizations),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24.0),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: appLocalizations.newRoleLabel,
                    ),
                    hint: Text(appLocalizations.selectNewRoleHint),
                    items: _availableRoles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(_getRoleTranslation(role, appLocalizations)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                  ref.watch(familyControllerProvider).isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => _updateRole(member.role),
                          child: Text(appLocalizations.updateRoleButton),
                        ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
