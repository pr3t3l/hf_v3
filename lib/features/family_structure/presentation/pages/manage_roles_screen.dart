import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/l10n/app_localizations.dart';

final memberDocumentProvider = StreamProvider.autoDispose
    .family<FamilyMember, ({String familyId, String memberId})>(
        (ref, ids) => ref.watch(familyServiceProvider).getMemberDocument(ids.familyId, ids.memberId));

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

  void _updateRole(FamilyMember member) async {
    if (_selectedRole == null || _selectedRole == member.role) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      await ref.read(familyControllerProvider.notifier).updateMemberRole(
            widget.familyId,
            widget.memberUserId,
            _selectedRole!,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final memberAsyncValue = ref.watch(memberDocumentProvider((familyId: widget.familyId, memberId: widget.memberUserId)));

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.manageRolesTitle)),
      body: memberAsyncValue.when(
        data: (member) {
          _selectedRole ??= member.role;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(appLocalizations.manageRoleFor(member.displayName), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16.0),
                Text(appLocalizations.currentRoleLabel(appLocalizations.roleLabel(member.role))),
                const SizedBox(height: 24.0),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _availableRoles.map((role) => DropdownMenuItem(value: role, child: Text(appLocalizations.roleLabel(role)))).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  decoration: InputDecoration(labelText: appLocalizations.newRoleLabel),
                ),
                const SizedBox(height: 24.0),
                ref.watch(familyControllerProvider).isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => _updateRole(member),
                        child: Text(appLocalizations.updateRoleButton),
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
}
