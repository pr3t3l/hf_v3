// hf_v3/lib/features/family_structure/presentation/pages/join_family_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/features/family_structure/presentation/controllers/family_controller.dart';
import 'package:hf_v3/features/family_structure/data/models/invitation.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart'; // Import FamilyService

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _invitationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Invitation? _invitationDetails; // To store fetched invitation details
  bool _isLoadingInvitation = false; // To show loading for invitation fetch

  @override
  void dispose() {
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvitationDetails() async {
    if (_invitationCodeController.text.trim().isEmpty) {
      setState(() {
        _invitationDetails = null;
      });
      return;
    }

    setState(() {
      _isLoadingInvitation = true;
      _invitationDetails = null;
    });

    try {
      // Use the new method in FamilyService to fetch invitation details
      final invitation = await ref
          .read(familyServiceProvider)
          .getInvitationByCode(
            _invitationCodeController.text.trim().toUpperCase(),
          );

      setState(() {
        _invitationDetails = invitation;
      });
    } catch (e) {
      // Use a logging framework instead of print in production
      debugPrint(
        'Error fetching invitation details: $e',
      ); // Use debugPrint for development
      setState(() {
        _invitationDetails = null;
      });
    } finally {
      setState(() {
        _isLoadingInvitation = false;
      });
    }
  }

  Future<void> _joinFamily() async {
    if (_formKey.currentState!.validate()) {
      final familyController = ref.read(familyControllerProvider.notifier);
      try {
        await familyController.joinFamily(
          _invitationCodeController.text.trim(),
        );
        if (mounted) {
          // Guard against BuildContext across async gaps
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.familyJoinedSuccess,
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
          Navigator.of(context).pop(); // Go back to family selection screen
        }
      } catch (e) {
        if (mounted) {
          // Guard against BuildContext across async gaps
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.familyJoinedError(e.toString()),
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
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyControllerProvider);
    final appLocalizations = AppLocalizations.of(context)!;
    final familyService = ref.read(
      familyServiceProvider,
    ); // Get FamilyService to fetch family names

    return Scaffold(
      appBar: AppBar(title: Text(appLocalizations.joinFamilyTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appLocalizations.joinFamilyDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                TextFormField(
                  controller: _invitationCodeController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.invitationCodeLabel,
                    hintText: appLocalizations.invitationCodeHint,
                  ),
                  textCapitalization:
                      TextCapitalization.characters, // For easier code entry
                  onChanged: (value) {
                    // Trigger fetch details after a short delay or on blur
                    if (value.length == 8) {
                      // Assuming 8 char code
                      _fetchInvitationDetails();
                    } else {
                      setState(() {
                        _invitationDetails = null;
                        _isLoadingInvitation = false;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.invitationCodeRequired;
                    }
                    if (value.length != 8) {
                      // Assuming 8 char code
                      return appLocalizations.invitationCodeInvalidLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _isLoadingInvitation
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : _invitationDetails != null
                    ? Card(
                        color: Theme.of(context).colorScheme.surface,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appLocalizations.invitationDetailsTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appLocalizations.invitationFrom(
                                  _invitationDetails!.invitedByDisplayName,
                                ),
                              ),
                              // Fetch family name using FutureBuilder
                              FutureBuilder<String>(
                                future: familyService.getFamilyName(
                                  _invitationDetails!.familyId,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      appLocalizations.invitationToFamily(
                                        '...',
                                      ),
                                    ); // Placeholder
                                  } else if (snapshot.hasError) {
                                    return Text(
                                      appLocalizations.invitationToFamily(
                                        'Error',
                                      ),
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
                                  _invitationDetails!.expiresAt
                                      .toDate()
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _invitationCodeController.text.isNotEmpty &&
                          !_isLoadingInvitation
                    ? Text(
                        appLocalizations.noInvitationFound,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : const SizedBox.shrink(), // No details to show yet
                const SizedBox(height: 24.0),
                familyState.isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : ElevatedButton(
                        onPressed: _invitationDetails != null
                            ? _joinFamily
                            : null, // Enable only if invitation details are fetched
                        style: Theme.of(context).elevatedButtonTheme.style,
                        child: Text(appLocalizations.joinFamilyButton),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
