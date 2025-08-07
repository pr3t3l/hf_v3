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
}
