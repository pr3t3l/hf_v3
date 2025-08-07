import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginError(Object error);

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First Name is required.'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last Name is required.'**
  String get lastNameRequired;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters, include an uppercase letter, a number, and a special character.'**
  String get passwordWeak;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please log in.'**
  String get registrationSuccess;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String registrationError(Object error);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkButton;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @passwordResetError.
  ///
  /// In en, this message translates to:
  /// **'Password reset failed: {error}'**
  String passwordResetError(Object error);

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeMessage(Object userName);

  /// No description provided for @homeDescription.
  ///
  /// In en, this message translates to:
  /// **'This is your personalized family hub.'**
  String get homeDescription;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings coming soon!'**
  String get settingsComingSoon;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get navFamily;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get navGames;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @familySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Hub'**
  String get familySelectionTitle;

  /// No description provided for @noFamilyMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t belong to any family yet. Create one or join an existing one!'**
  String get noFamilyMessage;

  /// No description provided for @createFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Family'**
  String get createFamilyButton;

  /// No description provided for @joinFamilyButton.
  ///
  /// In en, this message translates to:
  /// **'Join Family'**
  String get joinFamilyButton;

  /// No description provided for @yourFamiliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Families'**
  String get yourFamiliesTitle;

  /// No description provided for @noExistingFamilies.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any families yet.'**
  String get noExistingFamilies;

  /// No description provided for @familyMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String familyMembersCount(num count);

  /// No description provided for @errorLoadingFamilies.
  ///
  /// In en, this message translates to:
  /// **'Error loading families: {error}'**
  String errorLoadingFamilies(Object error);

  /// No description provided for @createFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Family'**
  String get createFamilyTitle;

  /// No description provided for @createFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'Give your family a name to get started!'**
  String get createFamilyDescription;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Name'**
  String get familyNameLabel;

  /// No description provided for @familyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., The Smiths, My Awesome Family'**
  String get familyNameHint;

  /// No description provided for @familyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Family name is required.'**
  String get familyNameRequired;

  /// No description provided for @familyCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Family created successfully!'**
  String get familyCreatedSuccess;

  /// No description provided for @familyCreatedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create family: {error}'**
  String familyCreatedError(Object error);

  /// No description provided for @joinFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a Family'**
  String get joinFamilyTitle;

  /// No description provided for @joinFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the invitation code you received.'**
  String get joinFamilyDescription;

  /// No description provided for @invitationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation Code'**
  String get invitationCodeLabel;

  /// No description provided for @invitationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., ABC123XYZ'**
  String get invitationCodeHint;

  /// No description provided for @invitationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Invitation code is required.'**
  String get invitationCodeRequired;

  /// No description provided for @invitationCodeInvalidLength.
  ///
  /// In en, this message translates to:
  /// **'Invitation code must be 8 characters long.'**
  String get invitationCodeInvalidLength;

  /// No description provided for @invitationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation Details'**
  String get invitationDetailsTitle;

  /// No description provided for @invitationFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {inviterName}'**
  String invitationFrom(Object inviterName);

  /// No description provided for @invitationToFamily.
  ///
  /// In en, this message translates to:
  /// **'To Family: {familyName}'**
  String invitationToFamily(Object familyName);

  /// No description provided for @invitationExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String invitationExpires(Object date);

  /// No description provided for @noInvitationFound.
  ///
  /// In en, this message translates to:
  /// **'No valid pending invitation found for this code.'**
  String get noInvitationFound;

  /// No description provided for @familyJoinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the family!'**
  String get familyJoinedSuccess;

  /// No description provided for @familyJoinedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to join family: {error}'**
  String familyJoinedError(Object error);

  /// No description provided for @familyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Details'**
  String get familyDetailsTitle;

  /// No description provided for @registeredMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered Members'**
  String get registeredMembersTitle;

  /// No description provided for @unregisteredMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Family Members'**
  String get unregisteredMembersTitle;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteUnregisteredMember.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {memberName} from this family?'**
  String confirmDeleteUnregisteredMember(Object memberName);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @memberRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member removed successfully.'**
  String get memberRemovedSuccess;

  /// No description provided for @memberRemovedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member: {error}'**
  String memberRemovedError(Object error);

  /// No description provided for @inviteMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMemberButton;

  /// No description provided for @viewFamilyTreeButton.
  ///
  /// In en, this message translates to:
  /// **'View Family Tree'**
  String get viewFamilyTreeButton;

  /// No description provided for @errorLoadingFamilyDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading family details: {error}'**
  String errorLoadingFamilyDetails(Object error);

  /// No description provided for @inviteMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite/Add Member'**
  String get inviteMemberTitle;

  /// No description provided for @registeredUserToggle.
  ///
  /// In en, this message translates to:
  /// **'Invite Registered User (by Email)'**
  String get registeredUserToggle;

  /// No description provided for @memberNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Member Name'**
  String get memberNameLabel;

  /// No description provided for @memberNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Grandma Ana, Fido'**
  String get memberNameHint;

  /// No description provided for @memberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Member name is required.'**
  String get memberNameRequired;

  /// No description provided for @initialRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial Role'**
  String get initialRoleLabel;

  /// No description provided for @selectRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Select a role'**
  String get selectRoleHint;

  /// No description provided for @roleRequired.
  ///
  /// In en, this message translates to:
  /// **'Role is required.'**
  String get roleRequired;

  /// No description provided for @initialRelationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship Type'**
  String get initialRelationshipLabel;

  /// No description provided for @selectRelationshipHint.
  ///
  /// In en, this message translates to:
  /// **'Select relationship'**
  String get selectRelationshipHint;

  /// No description provided for @relationshipRequired.
  ///
  /// In en, this message translates to:
  /// **'Relationship type is required.'**
  String get relationshipRequired;

  /// No description provided for @isDeceasedLabel.
  ///
  /// In en, this message translates to:
  /// **'Is Deceased?'**
  String get isDeceasedLabel;

  /// No description provided for @isPetLabel.
  ///
  /// In en, this message translates to:
  /// **'Is Pet?'**
  String get isPetLabel;

  /// No description provided for @sendInvitationButton.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitationButton;

  /// No description provided for @addMemberButton.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberButton;

  /// No description provided for @invitationSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully!'**
  String get invitationSentSuccess;

  /// No description provided for @memberAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member added successfully!'**
  String get memberAddedSuccess;

  /// No description provided for @invitationSentError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation: {error}'**
  String invitationSentError(Object error);

  /// No description provided for @memberAddedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to add member: {error}'**
  String memberAddedError(Object error);

  /// No description provided for @manageRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Member Role'**
  String get manageRolesTitle;

  /// No description provided for @manageRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Managing role for: {memberName}'**
  String manageRoleFor(Object memberName);

  /// No description provided for @currentRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Role: {role}'**
  String currentRoleLabel(Object role);

  /// No description provided for @newRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'New Role'**
  String get newRoleLabel;

  /// No description provided for @selectNewRoleHint.
  ///
  /// In en, this message translates to:
  /// **'Select new role'**
  String get selectNewRoleHint;

  /// No description provided for @newRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'New role is required.'**
  String get newRoleRequired;

  /// No description provided for @updateRoleButton.
  ///
  /// In en, this message translates to:
  /// **'Update Role'**
  String get updateRoleButton;

  /// No description provided for @roleUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully!'**
  String get roleUpdatedSuccess;

  /// No description provided for @roleUpdatedError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update role: {error}'**
  String roleUpdatedError(Object error);

  /// No description provided for @noFamilySelected.
  ///
  /// In en, this message translates to:
  /// **'No family selected'**
  String get noFamilySelected;

  /// No description provided for @errorLoadingFamiliesShort.
  ///
  /// In en, this message translates to:
  /// **'Error loading families.'**
  String get errorLoadingFamiliesShort;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'You have no pending family invitations.'**
  String get noPendingInvitations;

  /// No description provided for @invitationReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'New Family Invitation'**
  String get invitationReceivedTitle;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined.'**
  String get invitationDeclined;

  /// No description provided for @invitationDeclineError.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline invitation: {error}'**
  String invitationDeclineError(Object error);

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted!'**
  String get invitationAccepted;

  /// No description provided for @invitationAcceptError.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invitation: {error}'**
  String invitationAcceptError(Object error);

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications: {error}'**
  String errorLoadingNotifications(Object error);

  /// No description provided for @family_name_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Loading family name...'**
  String get family_name_placeholder;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'{type, select, parent{Parent} child{Child} guardian{Guardian} administrator{Administrator} other{Other}}'**
  String roleLabel(String type);

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'{type, select, sibling{Sibling} spouse{Spouse} cousin{Cousin} grandparent{Grandparent} other{Other} pet{Pet} deceased{Deceased}}'**
  String relationshipLabel(String type);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
