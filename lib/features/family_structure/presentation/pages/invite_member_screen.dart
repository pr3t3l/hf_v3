// hf_v3/lib/features/family_structure/presentation/pages/invite_member_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';

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

  String _getRoleTranslation(String role, AppLocalizations localizations) {
    switch (role) {
      case 'parent':
        return localizations.role_parent;
      case 'child':
        return localizations.role_child;
      case 'guardian':
        return localizations.role_guardian;
      case 'administrator':
        return localizations.role_administrator;
      default:
        return role; // Fallback
    }
  }

  String _getRelationshipTranslation(String type, AppLocalizations localizations) {
    switch (type) {
      case 'sibling':
        return localizations.relationship_sibling;
      case 'spouse':
        return localizations.relationship_spouse;
      case 'cousin':
        return localizations.relationship_cousin;
      case 'grandparent':
        return localizations.relationship_grandparent;
      case 'other':
        return localizations.relationship_other;
      case 'pet':
        return localizations.relationship_pet;
      case 'deceased':
        return localizations.relationship_deceased;
      default:
        return type;
    }
  }

  Future<void> _inviteMember() async {
    if (_formKey.currentState!.validate()) {
      final familyController = ref.read(familyControllerProvider.notifier);
      try {
        await familyController.inviteMember(
          widget.familyId,
          _emailOrNameController.text.trim(),
          isRegisteredUser: _isRegisteredUser,
          initialRole: _selectedRole,
          initialRelationshipType: _selectedRelationshipType,
          isDeceased: _isDeceased,
          isPet: _isPet,
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
        }
      } catch (e) {
        if (!mounted) return;
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
                      // Reset specific fields when toggling
                      _isDeceased = false;
                      _isPet = false;
                      _selectedRole = null; // Role only applies to registered
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

                // Initial Role for Registered Users
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
                        return appLocalizations.roleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                ],

                // Relationship Type for both
                DropdownButtonFormField<String>(
                  value: _selectedRelationshipType,
                  decoration: InputDecoration(
                    labelText: appLocalizations.initialRelationshipLabel,
                  ),
                  hint: Text(appLocalizations.selectRelationshipHint),
                  items: _relationshipTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        _getRelationshipTranslation(type, appLocalizations),
                      ), // Localize relationships
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

                // Specific flags for Unregistered Members
                if (!_isRegisteredUser) ...[
                  CheckboxListTile(
                    title: Text(appLocalizations.isDeceasedLabel),
                    value: _isDeceased,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDeceased = value ?? false;
                        if (_isDeceased) _isPet = false; // Cannot be both
                        if (_isDeceased &&
                            _selectedRelationshipType != 'deceased') {
                          _selectedRelationshipType =
                              'deceased'; // Auto-set relationship
                        } else if (!_isDeceased &&
                            _selectedRelationshipType == 'deceased') {
                          _selectedRelationshipType =
                              null; // Clear if unchecked
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
                        if (_isPet) _isDeceased = false; // Cannot be both
                        if (_isPet && _selectedRelationshipType != 'pet') {
                          _selectedRelationshipType =
                              'pet'; // Auto-set relationship
                        } else if (!_isPet &&
                            _selectedRelationshipType == 'pet') {
                          _selectedRelationshipType =
                              null; // Clear if unchecked
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
