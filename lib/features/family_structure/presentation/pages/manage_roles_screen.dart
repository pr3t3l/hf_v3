// hf_v3/lib/features/family_structure/presentation/pages/manage_roles_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
// No need to import family.dart or family_member.dart here directly as data is passed via widget

class ManageRolesScreen extends ConsumerStatefulWidget {
  final String familyId;
  final String memberUserId; // The user whose role is being managed
  final String currentRole; // The current role of the member
  final String memberDisplayName; // NEW: Display name of the member

  const ManageRolesScreen({
    super.key,
    required this.familyId,
    required this.memberUserId,
    required this.currentRole,
    required this.memberDisplayName, // NEW: Required
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

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  String _getRoleTranslation(String role, AppLocalizations localizations) {
    switch (role) {
      case 'parent':
        return localizations.roleParent;
      case 'child':
        return localizations.roleChild;
      case 'guardian':
        return localizations.roleGuardian;
      case 'administrator':
        return localizations.roleAdministrator;
      default:
        return role; // Fallback
    }
  }

  Future<void> _updateRole() async {
    if (_selectedRole == null || _selectedRole == widget.currentRole) {
      if (mounted) {
        Navigator.of(context).pop();
      }
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
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
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.manageRolesTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appLocalizations.manageRoleFor(
                  widget.memberDisplayName,
                ), // Use display name here
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                appLocalizations.currentRoleLabel(
                  _getRoleTranslation(widget.currentRole, appLocalizations),
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
                    child: Text(
                      _getRoleTranslation(role, appLocalizations),
                    ), // Localize roles
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return appLocalizations.newRoleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              familyState.isLoading
                  ? CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : ElevatedButton(
                      onPressed: _updateRole,
                      style: Theme.of(context).elevatedButtonTheme.style,
                      child: Text(appLocalizations.updateRoleButton),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
