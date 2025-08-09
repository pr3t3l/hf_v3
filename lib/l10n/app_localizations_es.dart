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

  @override
  String get registerTitle => 'Registrarse';

  @override
  String get firstNameLabel => 'Nombre';

  @override
  String get lastNameLabel => 'Apellido';

  @override
  String get firstNameRequired => 'El nombre es obligatorio.';

  @override
  String get lastNameRequired => 'El apellido es obligatorio.';

  @override
  String get confirmPasswordLabel => 'Confirmar Contraseña';

  @override
  String get passwordWeak => 'La contraseña debe tener al menos 8 caracteres, incluir una mayúscula, un número y un carácter especial.';

  @override
  String get passwordMismatch => 'Las contraseñas no coinciden.';

  @override
  String get registrationSuccess => '¡Registro exitoso! Por favor, inicia sesión.';

  @override
  String registrationError(Object error) {
    return 'Error al registrarse: $error';
  }

  @override
  String get forgotPasswordTitle => 'Olvidé Contraseña';

  @override
  String get sendResetLinkButton => 'Enviar Enlace de Restablecimiento';

  @override
  String get passwordResetEmailSent => 'Correo de restablecimiento de contraseña enviado. Revisa tu bandeja de entrada.';

  @override
  String passwordResetError(Object error) {
    return 'Error al restablecer contraseña: $error';
  }

  @override
  String get homeTitle => 'Inicio';

  @override
  String welcomeMessage(Object userName) {
    return '¡Bienvenido/a, $userName!';
  }

  @override
  String get homeDescription => 'Este es tu centro familiar personalizado.';

  @override
  String get settingsComingSoon => '¡Configuración próxima!';

  @override
  String get navHome => 'Inicio';

  @override
  String get navFamily => 'Familia';

  @override
  String get navJournal => 'Diario';

  @override
  String get navGames => 'Juegos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get familySelectionTitle => 'Centro Familiar';

  @override
  String get noFamilyMessage => 'Aún no perteneces a ninguna familia. ¡Crea una o únete a una existente!';

  @override
  String get createFamilyButton => 'Crear Nueva Familia';

  @override
  String get joinFamilyButton => 'Unirse a Familia';

  @override
  String get yourFamiliesTitle => 'Tus Familias';

  @override
  String get noExistingFamilies => 'Aún no te has unido a ninguna familia.';

  @override
  String familyMembersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String errorLoadingFamilies(Object error) {
    return 'Error al cargar familias: $error';
  }

  @override
  String get createFamilyTitle => 'Crear Nueva Familia';

  @override
  String get createFamilyDescription => '¡Dale un nombre a tu familia para empezar!';

  @override
  String get familyNameLabel => 'Nombre de la Familia';

  @override
  String get familyNameHint => 'Ej: Los García, Mi Familia Genial';

  @override
  String get familyNameRequired => 'El nombre de la familia es obligatorio.';

  @override
  String get familyCreatedSuccess => '¡Familia creada con éxito!';

  @override
  String familyCreatedError(Object error) {
    return 'Error al crear familia: $error';
  }

  @override
  String get joinFamilyTitle => 'Unirse a una Familia';

  @override
  String get joinFamilyDescription => 'Introduce el código de invitación que recibiste.';

  @override
  String get invitationCodeLabel => 'Código de Invitación';

  @override
  String get invitationCodeHint => 'Ej: ABC123XYZ';

  @override
  String get invitationCodeRequired => 'El código de invitación es obligatorio.';

  @override
  String get invitationCodeInvalidLength => 'El código de invitación debe tener 8 caracteres.';

  @override
  String get invitationDetailsTitle => 'Detalles de la Invitación';

  @override
  String invitationFrom(Object inviterName) {
    return 'De: $inviterName';
  }

  @override
  String invitationToFamily(Object familyName) {
    return 'A la Familia: $familyName';
  }

  @override
  String invitationExpires(Object date) {
    return 'Expira: $date';
  }

  @override
  String get noInvitationFound => 'No se encontró ninguna invitación pendiente válida para este código.';

  @override
  String get familyJoinedSuccess => '¡Te has unido a la familia con éxito!';

  @override
  String familyJoinedError(Object error) {
    return 'Error al unirse a la familia: $error';
  }

  @override
  String get familyDetailsTitle => 'Detalles de la Familia';

  @override
  String get registeredMembersTitle => 'Miembros Registrados';

  @override
  String get unregisteredMembersTitle => 'Otros Miembros de la Familia';

  @override
  String get confirmDeleteTitle => 'Confirmar Eliminación';

  @override
  String confirmDeleteUnregisteredMember(Object memberName) {
    return '¿Estás seguro de que quieres eliminar a $memberName de esta familia?';
  }

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get memberRemovedSuccess => 'Miembro eliminado con éxito.';

  @override
  String memberRemovedError(Object error) {
    return 'Error al eliminar miembro: $error';
  }

  @override
  String get leaveFamilyButton => 'Salir de la Familia';

  @override
  String get confirmLeaveFamilyTitle => 'Confirmar salida';

  @override
  String get confirmLeaveFamilyMessage =>
      '¿Estás seguro de que quieres salir de esta familia?';

  @override
  String get leaveButton => 'Salir';

  @override
  String get leaveFamilySuccess => 'Has salido de la familia.';

  @override
  String leaveFamilyError(Object error) {
    return 'Error al salir de la familia: $error';
  }

  @override
  String get inviteMemberButton => 'Invitar Miembro';

  @override
  String get viewFamilyTreeButton => 'Ver Árbol Familiar';

  @override
  String errorLoadingFamilyDetails(Object error) {
    return 'Error al cargar detalles de la familia: $error';
  }

  @override
  String get inviteMemberTitle => 'Invitar/Añadir Miembro';

  @override
  String get registeredUserToggle => 'Invitar Usuario Registrado (por Email)';

  @override
  String get memberNameLabel => 'Nombre del Miembro';

  @override
  String get memberNameHint => 'Ej: Abuela Ana, Fido';

  @override
  String get memberNameRequired => 'El nombre del miembro es obligatorio.';

  @override
  String get initialRoleLabel => 'Rol Inicial';

  @override
  String get selectRoleHint => 'Selecciona un rol';

  @override
  String get roleRequired => 'El rol es obligatorio.';

  @override
  String get initialRelationshipLabel => 'Tipo de Relación';

  @override
  String get selectRelationshipHint => 'Selecciona el tipo de relación';

  @override
  String get relationshipRequired => 'El tipo de relación es obligatorio.';

  @override
  String get isDeceasedLabel => '¿Es Fallecido?';

  @override
  String get isPetLabel => '¿Es Mascota?';

  @override
  String get sendInvitationButton => 'Enviar Invitación';

  @override
  String get addMemberButton => 'Añadir Miembro';

  @override
  String get invitationSentSuccess => '¡Invitación enviada con éxito!';

  @override
  String get memberAddedSuccess => '¡Miembro añadido con éxito!';

  @override
  String invitationSentError(Object error) {
    return 'Error al enviar invitación: $error';
  }

  @override
  String memberAddedError(Object error) {
    return 'Error al añadir miembro: $error';
  }

  @override
  String get manageRolesTitle => 'Gestionar Rol del Miembro';

  @override
  String manageRoleFor(Object memberName) {
    return 'Gestionando rol para: $memberName';
  }

  @override
  String currentRoleLabel(Object role) {
    return 'Rol Actual: $role';
  }

  @override
  String get newRoleLabel => 'Nuevo Rol';

  @override
  String get selectNewRoleHint => 'Selecciona nuevo rol';

  @override
  String get newRoleRequired => 'El nuevo rol es obligatorio.';

  @override
  String get updateRoleButton => 'Actualizar Rol';

  @override
  String get roleUpdatedSuccess => '¡Rol actualizado con éxito!';

  @override
  String roleUpdatedError(Object error) {
    return 'Error al actualizar rol: $error';
  }

  @override
  String get noFamilySelected => 'Ninguna familia seleccionada';

  @override
  String get errorLoadingFamiliesShort => 'Error al cargar familias.';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get noPendingInvitations => 'No tienes invitaciones familiares pendientes.';

  @override
  String get invitationReceivedTitle => 'Nueva Invitación Familiar';

  @override
  String get declineButton => 'Rechazar';

  @override
  String get invitationDeclined => 'Invitación rechazada.';

  @override
  String invitationDeclineError(Object error) {
    return 'Error al rechazar invitación: $error';
  }

  @override
  String get acceptButton => 'Aceptar';

  @override
  String get invitationAccepted => '¡Invitación aceptada!';

  @override
  String invitationAcceptError(Object error) {
    return 'Error al aceptar invitación: $error';
  }

  @override
  String errorLoadingNotifications(Object error) {
    return 'Error al cargar notificaciones: $error';
  }

  @override
  String get family_name_placeholder => 'Cargando nombre de familia...';

  @override
  String roleLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'parent': 'Padre/Madre',
        'child': 'Hijo/a',
        'guardian': 'Tutor/a',
        'administrator': 'Administrador/a',
        'other': 'Otro',
      },
    );
    return '$_temp0';
  }

  @override
  String relationshipLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'sibling': 'Hermano/a',
        'spouse': 'Cónyuge',
        'cousin': 'Primo/a',
        'grandparent': 'Abuelo/a',
        'other': 'Otro',
        'pet': 'Mascota',
        'deceased': 'Fallecido/a',
      },
    );
    return '$_temp0';
  }

  @override
  String get confirmPasswordRequired => 'Confirmar contraseña es obligatorio.';

  @override
  String get emailHint => 'Introducir correo electrónico';

  @override
  String get role_parent => 'Padre/Madre';

  @override
  String get role_child => 'Hijo/a';

  @override
  String get role_guardian => 'Tutor/a';

  @override
  String get role_administrator => 'Administrador/a';

  @override
  String get relationship_sibling => 'Hermano/a';

  @override
  String get relationship_spouse => 'Cónyuge';

  @override
  String get relationship_cousin => 'Primo/a';

  @override
  String get relationship_grandparent => 'Abuelo/a';

  @override
  String get relationship_other => 'Otro';

  @override
  String get relationship_pet => 'Mascota';

  @override
  String get relationship_deceased => 'Fallecido/a';
}
