// lib/features/family_structure/presentation/pages/invite_member_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
// Eliminado el import: import 'package:flutter/foundation.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  final String familyId;
  const InviteMemberScreen({super.key, required this.familyId});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final _emailOrNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegisteredUser = true; // Toggle for registered/unregistered
  String? _selectedRole; // For registered users
  String? _selectedRelationshipType; // For both
  bool _isDeceased = false; // For unregistered members
  bool _isPet = false; // For unregistered members

  final List<String> _roles = ['parent', 'child', 'guardian', 'administrator'];
  final List<String> _relationshipTypes = [
    'sibling',
    'spouse',
    'cousin',
    'grandparent',
    'other',
    'pet',
    'deceased',
  ];

  @override
  void dispose() {
    _emailOrNameController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    debugPrint('InviteMemberScreen: _inviteMember llamado.');
    if (_formKey.currentState!.validate()) {
      debugPrint('InviteMemberScreen: Formulario validado.');
      final familyController = ref.read(familyControllerProvider.notifier);
      try {
        final emailToInvite = _isRegisteredUser
            ? _emailOrNameController.text.trim().toLowerCase()
            : _emailOrNameController.text
                  .trim(); // Normalize email to lowercase
        debugPrint(
          'InviteMemberScreen: Llamando a familyController.inviteMember con los siguientes datos:',
        );
        debugPrint('  familyId: ${widget.familyId}');
        debugPrint('  emailOrName: $emailToInvite');
        debugPrint('  isRegisteredUser: $_isRegisteredUser');
        debugPrint('  initialRole: $_selectedRole');
        debugPrint('  initialRelationshipType: $_selectedRelationshipType');
        debugPrint('  isDeceased: $_isDeceased');
        debugPrint('  isPet: $_isPet');

        await familyController.inviteMember(
          widget.familyId,
          emailToInvite, // Usar el correo normalizado
          isRegisteredUser: _isRegisteredUser,
          initialRole: _selectedRole,
          initialRelationshipType: _selectedRelationshipType,
          isDeceased: _isDeceased,
          isPet: _isPet,
        );
        debugPrint(
          'InviteMemberScreen: familyController.inviteMember completado con éxito.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isRegisteredUser
                    ? AppLocalizations.of(context)!.invitationSentSuccess
                    : AppLocalizations.of(context)!.memberAddedSuccess,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop(); // Go back to family details
          debugPrint(
            'InviteMemberScreen: Navegación de vuelta a FamilyDetailsScreen.',
          );
        }
      } catch (e) {
        debugPrint(
          'InviteMemberScreen: Error al llamar a familyController.inviteMember: $e',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isRegisteredUser
                    ? AppLocalizations.of(
                        context,
                      )!.invitationSentError(e.toString())
                    : AppLocalizations.of(
                        context,
                      )!.memberAddedError(e.toString()),
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } else {
      debugPrint('InviteMemberScreen: Formulario NO validado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.inviteMemberTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SwitchListTile(
                  title: Text(appLocalizations.registeredUserToggle),
                  value: _isRegisteredUser,
                  onChanged: (bool value) {
                    setState(() {
                      _isRegisteredUser = value;
                      _isDeceased = false;
                      _isPet = false;
                      _selectedRole = null;
                      _selectedRelationshipType = null;
                      _emailOrNameController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailOrNameController,
                  decoration: InputDecoration(
                    labelText: _isRegisteredUser
                        ? appLocalizations.emailLabel
                        : appLocalizations.memberNameLabel,
                    hintText: _isRegisteredUser
                        ? appLocalizations.emailHint
                        : appLocalizations.memberNameHint,
                  ),
                  keyboardType: _isRegisteredUser
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isRegisteredUser
                          ? appLocalizations.emailRequired
                          : appLocalizations.memberNameRequired;
                    }
                    if (_isRegisteredUser &&
                        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return appLocalizations.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                if (_isRegisteredUser) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: appLocalizations.initialRoleLabel,
                    ),
                    hint: Text(appLocalizations.selectRoleHint),
                    items: _roles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(appLocalizations.roleLabel(role)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return appLocalizations.roleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
                DropdownButtonFormField<String>(
                  value: _selectedRelationshipType,
                  decoration: InputDecoration(
                    labelText: appLocalizations.initialRelationshipLabel,
                  ),
                  hint: Text(appLocalizations.selectRelationshipHint),
                  items: _relationshipTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(appLocalizations.relationshipLabel(type)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRelationshipType = newValue;
                      if (newValue == 'pet') {
                        _isPet = true;
                        _isDeceased = false;
                      } else if (newValue == 'deceased') {
                        _isDeceased = true;
                        _isPet = false;
                      } else {
                        _isPet = false;
                        _isDeceased = false;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return appLocalizations.relationshipRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                if (!_isRegisteredUser) ...[
                  CheckboxListTile(
                    title: Text(appLocalizations.isDeceasedLabel),
                    value: _isDeceased,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDeceased = value ?? false;
                        if (_isDeceased) _isPet = false;
                        if (_isDeceased &&
                            _selectedRelationshipType != 'deceased') {
                          _selectedRelationshipType = 'deceased';
                        } else if (!_isDeceased &&
                            _selectedRelationshipType == 'deceased') {
                          _selectedRelationshipType = null;
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(appLocalizations.isPetLabel),
                    value: _isPet,
                    onChanged: (bool? value) {
                      setState(() {
                        _isPet = value ?? false;
                        if (_isPet) _isDeceased = false;
                        if (_isPet && _selectedRelationshipType != 'pet') {
                          _selectedRelationshipType = 'pet';
                        } else if (!_isPet &&
                            _selectedRelationshipType == 'pet') {
                          _selectedRelationshipType = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],
                familyState.isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : ElevatedButton(
                        onPressed: _inviteMember,
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: Text(
                          _isRegisteredUser
                              ? appLocalizations.sendInvitationButton
                              : appLocalizations.addMemberButton,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
