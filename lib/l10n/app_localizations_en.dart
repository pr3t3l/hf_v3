// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get forgotPasswordButton => 'Forgot Password?';

  @override
  String get registerButton => 'Register';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get emailInvalid => 'Please enter a valid email.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String loginError(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get registerTitle => 'Register';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get firstNameRequired => 'First Name is required.';

  @override
  String get lastNameRequired => 'Last Name is required.';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordWeak => 'Password must be at least 8 characters, include an uppercase letter, a number, and a special character.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get registrationSuccess => 'Registration successful! Please log in.';

  @override
  String registrationError(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get passwordResetEmailSent => 'Password reset email sent. Check your inbox.';

  @override
  String passwordResetError(Object error) {
    return 'Password reset failed: $error';
  }

  @override
  String get homeTitle => 'Home';

  @override
  String welcomeMessage(Object userName) {
    return 'Welcome, $userName!';
  }

  @override
  String get homeDescription => 'This is your personalized family hub.';

  @override
  String get familySelectionTitle => 'Family Hub';

  @override
  String get noFamilyMessage => 'You don\'t belong to any family yet. Create one or join an existing one!';

  @override
  String get createFamilyButton => 'Create New Family';

  @override
  String get joinFamilyButton => 'Join Family';

  @override
  String get yourFamiliesTitle => 'Your Families';

  @override
  String get noExistingFamilies => 'You haven\'t joined any families yet.';

  @override
  String familyMembersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String errorLoadingFamilies(Object error) {
    return 'Error loading families: $error';
  }

  @override
  String get createFamilyTitle => 'Create New Family';

  @override
  String get createFamilyDescription => 'Give your family a name to get started!';

  @override
  String get familyNameLabel => 'Family Name';

  @override
  String get familyNameHint => 'e.g., The Smiths, My Awesome Family';

  @override
  String get familyNameRequired => 'Family name is required.';

  @override
  String get familyCreatedSuccess => 'Family created successfully!';

  @override
  String familyCreatedError(Object error) {
    return 'Failed to create family: $error';
  }

  @override
  String get joinFamilyTitle => 'Join a Family';

  @override
  String get joinFamilyDescription => 'Enter the invitation code you received.';

  @override
  String get invitationCodeLabel => 'Invitation Code';

  @override
  String get invitationCodeHint => 'e.g., ABC123XYZ';

  @override
  String get invitationCodeRequired => 'Invitation code is required.';

  @override
  String get invitationCodeInvalidLength => 'Invitation code must be 8 characters long.';

  @override
  String get invitationDetailsTitle => 'Invitation Details';

  @override
  String invitationFrom(Object inviterName) {
    return 'From: $inviterName';
  }

  @override
  String invitationToFamily(Object familyName) {
    return 'To Family: $familyName';
  }

  @override
  String invitationExpires(Object date) {
    return 'Expires: $date';
  }

  @override
  String get noInvitationFound => 'No valid pending invitation found for this code.';

  @override
  String get familyJoinedSuccess => 'Successfully joined the family!';

  @override
  String familyJoinedError(Object error) {
    return 'Failed to join family: $error';
  }

  @override
  String get familyDetailsTitle => 'Family Details';

  @override
  String get registeredMembersTitle => 'Registered Members';

  @override
  String get unregisteredMembersTitle => 'Other Family Members';

  @override
  String relationshipLabel(Object type) {
    return 'Relationship: $type';
  }

  @override
  String get confirmDeleteTitle => 'Confirm Deletion';

  @override
  String confirmDeleteUnregisteredMember(Object memberName) {
    return 'Are you sure you want to remove $memberName from this family?';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get memberRemovedSuccess => 'Member removed successfully.';

  @override
  String memberRemovedError(Object error) {
    return 'Failed to remove member: $error';
  }

  @override
  String get inviteMemberButton => 'Invite Member';

  @override
  String get viewFamilyTreeButton => 'View Family Tree';

  @override
  String errorLoadingFamilyDetails(Object error) {
    return 'Error loading family details: $error';
  }

  @override
  String get inviteMemberTitle => 'Invite/Add Member';

  @override
  String get registeredUserToggle => 'Invite Registered User (by Email)';

  @override
  String get memberNameLabel => 'Member Name';

  @override
  String get memberNameHint => 'e.g., Grandma Ana, Fido';

  @override
  String get memberNameRequired => 'Member name is required.';

  @override
  String get initialRoleLabel => 'Initial Role';

  @override
  String get selectRoleHint => 'Select a role';

  @override
  String get roleRequired => 'Role is required.';

  @override
  String get initialRelationshipLabel => 'Relationship Type';

  @override
  String get selectRelationshipHint => 'Select relationship';

  @override
  String get relationshipRequired => 'Relationship type is required.';

  @override
  String get isDeceasedLabel => 'Is Deceased?';

  @override
  String get isPetLabel => 'Is Pet?';

  @override
  String get sendInvitationButton => 'Send Invitation';

  @override
  String get addMemberButton => 'Add Member';

  @override
  String get invitationSentSuccess => 'Invitation sent successfully!';

  @override
  String get memberAddedSuccess => 'Member added successfully!';

  @override
  String invitationSentError(Object error) {
    return 'Failed to send invitation: $error';
  }

  @override
  String memberAddedError(Object error) {
    return 'Failed to add member: $error';
  }

  @override
  String get manageRolesTitle => 'Manage Member Role';

  @override
  String manageRoleFor(Object memberName) {
    return 'Managing role for: $memberName';
  }

  @override
  String currentRoleLabel(Object role) {
    return 'Current Role: $role';
  }

  @override
  String get newRoleLabel => 'New Role';

  @override
  String get selectNewRoleHint => 'Select new role';

  @override
  String get newRoleRequired => 'New role is required.';

  @override
  String get updateRoleButton => 'Update Role';

  @override
  String get roleUpdatedSuccess => 'Role updated successfully!';

  @override
  String roleUpdatedError(Object error) {
    return 'Failed to update role: $error';
  }

  @override
  String get noFamilySelected => 'No family selected';

  @override
  String get errorLoadingFamiliesShort => 'Error loading families.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noPendingInvitations => 'You have no pending family invitations.';

  @override
  String get invitationReceivedTitle => 'New Family Invitation';

  @override
  String get declineButton => 'Decline';

  @override
  String get invitationDeclined => 'Invitation declined.';

  @override
  String invitationDeclineError(Object error) {
    return 'Failed to decline invitation: $error';
  }

  @override
  String get acceptButton => 'Accept';

  @override
  String get invitationAccepted => 'Invitation accepted!';

  @override
  String invitationAcceptError(Object error) {
    return 'Failed to accept invitation: $error';
  }

  @override
  String errorLoadingNotifications(Object error) {
    return 'Error loading notifications: $error';
  }

  @override
  String get role_parent => 'Parent';

  @override
  String get role_child => 'Child';

  @override
  String get role_guardian => 'Guardian';

  @override
  String get role_administrator => 'Administrator';

  @override
  String get relationship_sibling => 'Sibling';

  @override
  String get relationship_spouse => 'Spouse';

  @override
  String get relationship_cousin => 'Cousin';

  @override
  String get relationship_grandparent => 'Grandparent';

  @override
  String get relationship_other => 'Other';

  @override
  String get relationship_pet => 'Pet';

  @override
  String get relationship_deceased => 'Deceased';

  @override
  String get settingsComingSoon => 'Settings coming soon!';

  @override
  String get navHome => 'Home';

  @override
  String get navFamily => 'Family';

  @override
  String get navJournal => 'Journal';

  @override
  String get navGames => 'Games';

  @override
  String get navProfile => 'Profile';

  @override
  String get confirmPasswordRequired => 'Confirm password is required.';

  @override
  String get emailHint => 'Enter email';
}
