// lib/features/family_structure/presentation/pages/invite_member_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';

// Enum to manage the invitation flow
enum InvitationFlow {
  registeredUser,
  unregisteredByEmail,
  unregisteredOther,
}

class InviteMemberScreen extends ConsumerStatefulWidget {
  final String familyId;
  const InviteMemberScreen({super.key, required this.familyId});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  InvitationFlow _flow = InvitationFlow.registeredUser;
  String? _selectedRole;
  String? _selectedRelationshipType;
  bool _isDeceased = false;
  bool _isPet = false;

  final List<String> _roles = ['parent', 'child', 'guardian', 'administrator'];
  final List<String> _relationshipTypes = ['sibling', 'spouse', 'cousin', 'grandparent', 'other'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    if (_formKey.currentState!.validate()) {
      final familyController = ref.read(familyControllerProvider.notifier);
      final value = _controller.text.trim();

      try {
        await familyController.inviteMember(
          widget.familyId,
          _flow == InvitationFlow.registeredUser ? value.toLowerCase() : value,
          isRegisteredUser: _flow == InvitationFlow.registeredUser,
          isUnregisteredUserEmail: _flow == InvitationFlow.unregisteredByEmail,
          initialRole: _selectedRole,
          initialRelationshipType: _selectedRelationshipType,
          isDeceased: _isDeceased,
          isPet: _isPet,
        );

        if (mounted) {
          // Determine the success message based on the flow
          String message;
          if (_flow == InvitationFlow.unregisteredByEmail) {
            message = AppLocalizations.of(context)!.invitationSentSuccess; // Same as registered
          } else if (_flow == InvitationFlow.unregisteredOther) {
            message = AppLocalizations.of(context)!.memberAddedSuccess;
          } else {
            message = AppLocalizations.of(context)!.invitationSentSuccess;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString(),
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
    }
  }

  void _onFlowChanged(InvitationFlow? newFlow) {
    if (newFlow == null) return;
    setState(() {
      _flow = newFlow;
      // Reset fields when flow changes
      _controller.clear();
      _selectedRole = null;
      _selectedRelationshipType = null;
      _isDeceased = false;
      _isPet = false;
    });
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
                DropdownButtonFormField<InvitationFlow>(
                  value: _flow,
                  decoration: InputDecoration(labelText: appLocalizations.invitationTypeLabel),
                  items: [
                    DropdownMenuItem(
                      value: InvitationFlow.registeredUser,
                      child: Text(appLocalizations.invitationTypeRegisteredUser),
                    ),
                    DropdownMenuItem(
                      value: InvitationFlow.unregisteredByEmail,
                      child: Text(appLocalizations.invitationTypeUnregisteredByEmail),
                    ),
                    DropdownMenuItem(
                      value: InvitationFlow.unregisteredOther,
                      child: Text(appLocalizations.invitationTypeUnregisteredOther),
                    ),
                  ],
                  onChanged: _onFlowChanged,
                ),
                const SizedBox(height: 16.0),
                _buildInputFormField(appLocalizations),
                const SizedBox(height: 16.0),
                if (_flow == InvitationFlow.registeredUser) _buildRoleDropdown(appLocalizations),
                if (_flow != InvitationFlow.registeredUser) _buildRelationshipDropdown(appLocalizations),
                if (_flow == InvitationFlow.unregisteredOther) ...[
                  const SizedBox(height: 16.0),
                  _buildPetCheckbox(appLocalizations),
                  _buildDeceasedCheckbox(appLocalizations),
                ],
                const SizedBox(height: 24.0),
                familyState.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _inviteMember,
                        child: Text(_getButtonText(appLocalizations)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFormField(AppLocalizations l10n) {
    bool isEmail = _flow == InvitationFlow.registeredUser || _flow == InvitationFlow.unregisteredByEmail;
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: isEmail ? l10n.emailLabel : l10n.memberNameLabel,
        hintText: isEmail ? l10n.emailHint : l10n.memberNameHint,
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isEmail ? l10n.emailRequired : l10n.memberNameRequired;
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return l10n.emailInvalid;
        }
        return null;
      },
    );
  }

  Widget _buildRoleDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(labelText: l10n.initialRoleLabel),
      hint: Text(l10n.selectRoleHint),
      items: _roles.map((String role) {
        return DropdownMenuItem<String>(value: role, child: Text(l10n.roleLabel(role)));
      }).toList(),
      onChanged: (String? newValue) => setState(() => _selectedRole = newValue),
      validator: (value) => value == null ? l10n.roleRequired : null,
    );
  }

  Widget _buildRelationshipDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedRelationshipType,
      decoration: InputDecoration(labelText: l10n.initialRelationshipLabel),
      hint: Text(l10n.selectRelationshipHint),
      items: _relationshipTypes.map((String type) {
        return DropdownMenuItem<String>(value: type, child: Text(l10n.relationshipLabel(type)));
      }).toList(),
      onChanged: (String? newValue) => setState(() => _selectedRelationshipType = newValue),
      validator: (value) => value == null ? l10n.relationshipRequired : null,
    );
  }

  Widget _buildPetCheckbox(AppLocalizations l10n) {
    return CheckboxListTile(
      title: Text(l10n.isPetLabel),
      value: _isPet,
      onChanged: (bool? value) {
        setState(() {
          _isPet = value ?? false;
          if (_isPet) _isDeceased = false;
        });
      },
    );
  }

  Widget _buildDeceasedCheckbox(AppLocalizations l10n) {
    return CheckboxListTile(
      title: Text(l10n.isDeceasedLabel),
      value: _isDeceased,
      onChanged: (bool? value) {
        setState(() {
          _isDeceased = value ?? false;
          if (_isDeceased) _isPet = false;
        });
      },
    );
  }

  String _getButtonText(AppLocalizations l10n) {
    switch (_flow) {
      case InvitationFlow.registeredUser:
      case InvitationFlow.unregisteredByEmail:
        return l10n.sendInvitationButton;
      case InvitationFlow.unregisteredOther:
        return l10n.addMemberButton;
    }
  }
}

// Add these to your AppLocalizations class
/*
abstract class AppLocalizations {
  // ... other strings
  String get invitationTypeLabel;
  String get invitationTypeRegisteredUser;
  String get invitationTypeUnregisteredByEmail;
  String get invitationTypeUnregisteredOther;
}

// In app_en.arb
"invitationTypeLabel": "Invitation Type",
"invitationTypeRegisteredUser": "Registered User (by Email)",
"invitationTypeUnregisteredByEmail": "Unregistered Person (by Email)",
"invitationTypeUnregisteredOther": "Other (Pet/Deceased)",

// In app_es.arb
"invitationTypeLabel": "Tipo de Invitación",
"invitationTypeRegisteredUser": "Usuario Registrado (por Email)",
"invitationTypeUnregisteredByEmail": "Persona no registrada (por Email)",
"invitationTypeUnregisteredOther": "Otro (Mascota/Fallecido)",
*/
