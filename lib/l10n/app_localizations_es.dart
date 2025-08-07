// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get emailLabel => 'Correo Electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get forgotPasswordButton => '¿Olvidaste tu Contraseña?';

  @override
  String get registerButton => 'Registrarse';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio.';

  @override
  String get emailInvalid => 'Por favor, introduce un correo electrónico válido.';

  @override
  String get passwordRequired => 'La contraseña es obligatoria.';

  @override
  String loginError(Object error) {
    return 'Error al iniciar sesión: $error';
  }
}
