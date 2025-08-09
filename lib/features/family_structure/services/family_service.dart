// hf_v3/lib/features/family_structure/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart'; // NEW: Import Cloud Functions

// Common models
import 'package:hf_v3/common/models/user_profile.dart';

// Family Structure specific models
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as family_model;
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/data/models/invitation.dart';

final familyServiceProvider = Provider<FamilyService>(
  (ref) => FamilyService(FirebaseFirestore.instance, FirebaseAuth.instance),
);

class FamilyService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final Uuid _uuid = const Uuid();
  final FirebaseFunctions _functions =
      FirebaseFunctions.instance; // NEW: Initialize Firebase Functions

  FamilyService(this._firestore, this._firebaseAuth);

  // Helper to get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // --- Family Creation ---
  Future<family_model.Family> createFamily(String familyName) async {
    debugPrint('FamilyService: Iniciando createFamily para: $familyName');
    if (currentUserId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception("User not authenticated.");
    }
    debugPrint('FamilyService: Usuario autenticado: $currentUserId');

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    if (!currentUserDoc.exists) {
      debugPrint(
        'FamilyService: Error - Perfil de usuario actual no encontrado.',
      );
      throw Exception("Current user profile not found.");
    }
    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);
    debugPrint(
      'FamilyService: Perfil de usuario cargado: ${currentUserProfile.displayName}',
    );

    final newFamilyRef = _firestore.collection('families').doc();
    final familyId = newFamilyRef.id;
    debugPrint('FamilyService: Generando nuevo Family ID: $familyId');

    final newFamily = family_model.Family(
      familyId: familyId,
      familyName: familyName,
      adminUserIds: [currentUserId!],
      memberUserIds: [
        FamilyMember(
          userId: currentUserId!,
          role: 'parent',
          displayName: currentUserProfile.displayName,
        ),
      ],
      unregisteredMembers: [],
      createdAt: Timestamp.now(),
      isActive: true,
    );
    debugPrint(
      'FamilyService: Objeto Family creado: ${newFamily.toFirestore()}',
    );

    final batch = _firestore.batch();

    batch.set(newFamilyRef, newFamily.toFirestore());
    debugPrint('FamilyService: Añadiendo creación de Family al batch.');

    batch.update(_firestore.collection('users').doc(currentUserId), {
      'familyIds': FieldValue.arrayUnion([familyId]),
    });
    debugPrint(
      'FamilyService: Añadiendo actualización de UserProfile al batch.',
    );

    try {
      await batch.commit();
      debugPrint(
        'FamilyService: Batch commit exitoso. Familia y perfil actualizados.',
      );
    } catch (e) {
      debugPrint('FamilyService: Error al hacer commit del batch: $e');
      rethrow;
    }
    return newFamily;
  }

  // --- Join Family ---
  Future<family_model.Family> joinFamily(String invitationCode) async {
    debugPrint(
      'FamilyService: Iniciando joinFamily para código: $invitationCode',
    );
    if (currentUserId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception("User not authenticated.");
    }

    final invitationsQuery = await _firestore
        .collection('invitations')
        .where('invitationCode', isEqualTo: invitationCode)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (invitationsQuery.docs.isEmpty) {
      debugPrint('FamilyService: Invitación inválida o expirada.');
      throw Exception("Invalid or expired invitation code.");
    }

    final invitationDoc = invitationsQuery.docs.first;
    final invitation = Invitation.fromFirestore(invitationDoc);
    debugPrint(
      'FamilyService: Invitación encontrada para familyId: ${invitation.familyId}',
    );

    final familyRef = _firestore
        .collection('families')
        .doc(invitation.familyId);
    final familyDoc = await familyRef.get();

    if (!familyDoc.exists) {
      debugPrint('FamilyService: Error - Familia no existe.');
      throw Exception("Family does not exist.");
    }

    final family = family_model.Family.fromFirestore(familyDoc);
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    // Check if user is already a member
    if (family.memberUserIds.any((member) => member.userId == currentUserId)) {
      debugPrint(
        'FamilyService: Error - Usuario ya es miembro de esta familia.',
      );
      throw Exception("You are already a member of this family.");
    }

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    if (!currentUserDoc.exists) {
      throw Exception("Current user profile not found.");
    }
    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);
    debugPrint(
      'FamilyService: Perfil de usuario actual cargado: ${currentUserProfile.displayName}',
    );

    final batch = _firestore.batch();

    batch.update(familyRef, {
      'memberUserIds': FieldValue.arrayUnion([
        FamilyMember(
          userId: currentUserId!,
          role: invitation.initialRole ?? 'child',
          displayName: currentUserProfile.displayName,
        ).toFirestore(),
      ]),
    });
    debugPrint('FamilyService: Añadiendo usuario a memberUserIds del batch.');

    batch.update(_firestore.collection('users').doc(currentUserId), {
      'familyIds': FieldValue.arrayUnion([invitation.familyId]),
    });
    debugPrint('FamilyService: Añadiendo familyId a user profile del batch.');

    batch.update(invitationDoc.reference, {'status': 'accepted'});
    debugPrint(
      'FamilyService: Actualizando estado de invitación a aceptada en el batch.',
    );

    // ignore: unnecessary_null_comparison
    if (invitation.invitedByUserId != null &&
        invitation.initialRelationshipType != null) {
      final relationshipId = _uuid.v4();
      batch.set(
        _firestore.collection('familyRelationships').doc(relationshipId),
        {
          'familyId': invitation.familyId,
          'member1Ref': {'type': 'user', 'id': invitation.invitedByUserId},
          'member2Ref': {'type': 'user', 'id': currentUserId},
          'relationshipType': invitation.initialRelationshipType,
          'dynamicType': 'initial_connection',
          'description': 'Relación establecida al unirse a la familia.',
          'frequency': 0.0,
          'lastInteraction': Timestamp.now(),
          'patterns': [],
          'iaConfidenceScore': 0.0,
          'interactionCount': 0,
        },
      );
      debugPrint('FamilyService: Creando relación inicial en el batch.');
    }

    try {
      await batch.commit();
      debugPrint('FamilyService: Batch commit exitoso para joinFamily.');
    } catch (e) {
      debugPrint(
        'FamilyService: Error al hacer commit del batch para joinFamily: $e',
      );
      rethrow;
    }
    return family_model.Family.fromFirestore(await familyRef.get());
  }

  // --- NEW: Fetch Invitation by Code ---
  Future<Invitation?> getInvitationByCode(String invitationCode) async {
    debugPrint(
      'FamilyService: Buscando invitación por código: $invitationCode',
    );
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('invitationCode', isEqualTo: invitationCode)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      debugPrint('FamilyService: Invitación encontrada.');
      return Invitation.fromFirestore(querySnapshot.docs.first);
    }
    debugPrint('FamilyService: No se encontró invitación.');
    return null;
  }

  // --- Invite Members (Now calls Cloud Function) ---
  Future<void> inviteMember(
    String familyId,
    String emailOrName, {
    required bool isRegisteredUser,
    String? initialRole,
    String? initialRelationshipType,
    bool isDeceased = false,
    bool isPet = false,
  }) async {
    debugPrint('FamilyService: Llamando a Cloud Function inviteFamilyMember.');
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'inviteFamilyMember',
      );
      final result = await callable.call({
        'familyId': familyId,
        'emailOrName': emailOrName,
        'isRegisteredUser': isRegisteredUser,
        'initialRole': initialRole,
        'initialRelationshipType': initialRelationshipType,
        'isDeceased': isDeceased,
        'isPet': isPet,
      });
      debugPrint('FamilyService: Respuesta de Cloud Function: ${result.data}');
      if (result.data['status'] != 'success') {
        throw Exception(
          result.data['message'] ?? 'Error desconocido al invitar miembro.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'FamilyService: Error de Cloud Function: ${e.code} - ${e.message}',
      );
      throw Exception('Error al invitar miembro: ${e.message}');
    } catch (e) {
      debugPrint('FamilyService: Error inesperado al invitar miembro: $e');
      throw Exception(
        'Failed to send invitation. This might be due to security rules. Please check the debug console for more details.',
      );
    }
  }

  // --- Fetch Family Details ---
  Stream<family_model.Family> getFamilyStream(String familyId) {
    debugPrint('FamilyService: Obteniendo stream para familyId: $familyId');
    return _firestore.collection('families').doc(familyId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        debugPrint(
          'FamilyService: Error - Family not found in stream for familyId: $familyId',
        );
        throw Exception("Family not found.");
      }
      return family_model.Family.fromFirestore(snapshot);
    });
  }

  // --- Fetch User's Families ---
  Stream<List<family_model.Family>> getUserFamiliesStream() {
    debugPrint(
      'FamilyService: Obteniendo stream de familias del usuario actual.',
    );
    if (currentUserId == null) {
      debugPrint(
        'FamilyService: Usuario no autenticado, retornando stream vacío.',
      );
      return Stream.value([]);
    }
    return _firestore.collection('users').doc(currentUserId).snapshots().asyncMap((
      userSnapshot,
    ) async {
      if (!userSnapshot.exists) {
        debugPrint(
          'FamilyService: Perfil de usuario no encontrado para stream.',
        );
        return [];
      }
      final userProfile = UserProfile.fromFirestore(userSnapshot);
      if (userProfile.familyIds.isEmpty) {
        debugPrint(
          'FamilyService: Usuario sin familias, retornando lista vacía.',
        );
        return [];
      }

      final families = <family_model.Family>[];
      debugPrint(
        'FamilyService: Cargando ${userProfile.familyIds.length} familias del usuario.',
      );
      for (final familyId in userProfile.familyIds) {
        final familyDoc = await _firestore
            .collection('families')
            .doc(familyId)
            .get();
        if (familyDoc.exists) {
          families.add(family_model.Family.fromFirestore(familyDoc));
        } else {
          debugPrint(
            'FamilyService: Advertencia - Familia con ID $familyId no encontrada para el usuario.',
          );
        }
      }
      debugPrint('FamilyService: Familias cargadas: ${families.length}');
      return families;
    });
  }

  // --- NEW: Get Pending Invitations Stream ---
  Stream<List<Invitation>> getPendingInvitationsStream() {
    debugPrint(
      'FamilyService: Obteniendo stream de invitaciones pendientes para el usuario actual.',
    );
    if (currentUserId == null) {
      debugPrint(
        'FamilyService: Usuario no autenticado, no hay invitaciones pendientes.',
      );
      return Stream.value([]);
    }
    return _firestore
        .collection('invitations')
        .where('invitedUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Invitation.fromFirestore(doc))
              .toList(),
        );
  }

  // --- NEW: Decline Invitation ---
  Future<void> declineInvitation(String invitationId) async {
    debugPrint('FamilyService: Declinando invitación con ID: $invitationId');
    if (currentUserId == null) {
      debugPrint(
        'FamilyService: Error - Usuario no autenticado para declinar invitación.',
      );
      throw Exception("User not authenticated.");
    }
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'declined',
    });
    debugPrint('FamilyService: Invitación $invitationId declinada con éxito.');
  }

  // --- NEW: Get Family Name by ID ---
  Future<String> getFamilyName(String familyId) async {
    debugPrint(
      'FamilyService: Obteniendo nombre de familia para ID: $familyId',
    );
    try {
      final familyDoc = await _firestore
          .collection('families')
          .doc(familyId)
          .get();
      if (familyDoc.exists) {
        final familyName = family_model.Family.fromFirestore(
          familyDoc,
        ).familyName;
        debugPrint('FamilyService: Nombre de familia encontrado: $familyName');
        return familyName;
      }
      debugPrint('FamilyService: Familia no encontrada para ID: $familyId');
      return 'Familia Desconocida'; // Default or localized string
    } catch (e) {
      debugPrint(
        'FamilyService: Error al obtener nombre de familia para ID $familyId: $e',
      );
      return 'Error al cargar nombre'; // Default or localized error string
    }
  }

  // --- Assign/Modify Member Role ---
  Future<void> updateMemberRole(
    String familyId,
    String memberUserId,
    String newRole,
  ) async {
    debugPrint(
      'FamilyService: Iniciando updateMemberRole para familyId: $familyId, memberUserId: $memberUserId, newRole: $newRole',
    );
    if (currentUserId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception("User not authenticated.");
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final familyDoc = await familyRef.get();
    if (!familyDoc.exists) {
      debugPrint('FamilyService: Error - Familia no encontrada.');
      throw Exception("Family not found.");
    }
    final family = family_model.Family.fromFirestore(familyDoc);
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    // Only admins can update roles
    if (!family.adminUserIds.contains(currentUserId)) {
      throw Exception("Only family administrators can update member roles.");
    }

    // Find and update the member's role
    final updatedMembers = family.memberUserIds.map((member) {
      if (member.userId == memberUserId) {
        return FamilyMember(
          userId: member.userId,
          role: newRole,
          displayName: member.displayName,
        );
      }
      return member;
    }).toList();
    debugPrint('FamilyService: Miembros actualizados localmente.');

    try {
      await familyRef.update({
        'memberUserIds': updatedMembers.map((m) => m.toFirestore()).toList(),
      });
      debugPrint('FamilyService: Rol de miembro actualizado en Firestore.');
    } catch (e) {
      debugPrint('FamilyService: Error al actualizar rol de miembro: $e');
      rethrow;
    }
  }

  // --- Remove Unregistered Member ---
  Future<void> removeUnregisteredMember(
    String familyId,
    String memberIdToRemove,
  ) async {
    debugPrint(
      'FamilyService: Iniciando removeUnregisteredMember para familyId: $familyId, memberIdToRemove: $memberIdToRemove',
    );
    if (currentUserId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception("User not authenticated.");
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final familyDoc = await familyRef.get();
    if (!familyDoc.exists) {
      debugPrint('FamilyService: Error - Familia no encontrada.');
      throw Exception("Family not found.");
    }
    final family = family_model.Family.fromFirestore(familyDoc);
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    // Only admins can remove unregistered members
    if (!family.adminUserIds.contains(currentUserId)) {
      throw Exception("Only family administrators can remove members.");
    }

    final updatedUnregisteredMembers = family.unregisteredMembers
        .where((member) => member.memberId != memberIdToRemove)
        .toList();
    debugPrint(
      'FamilyService: Miembros no registrados actualizados localmente.',
    );

    try {
      await familyRef.update({
        'unregisteredMembers': updatedUnregisteredMembers
            .map((m) => m.toFirestore())
            .toList(),
      });
      debugPrint(
        'FamilyService: Miembro no registrado eliminado en Firestore.',
      );
    } catch (e) {
      debugPrint('FamilyService: Error al eliminar miembro no registrado: $e');
      rethrow;
    }
  }

  // --- Leave Family ---
  Future<void> leaveFamily(String familyId) async {
    debugPrint('FamilyService: Iniciando leaveFamily para familyId: $familyId');
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception('User not authenticated.');
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final familyDoc = await familyRef.get();
    if (!familyDoc.exists) {
      debugPrint('FamilyService: Error - Familia no encontrada.');
      throw Exception('Family not found.');
    }

    final family = family_model.Family.fromFirestore(familyDoc);
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    if (!family.memberUserIds.any((m) => m.userId == userId)) {
      debugPrint('FamilyService: Error - Usuario no es miembro de la familia.');
      throw Exception('User is not a member of this family.');
    }

    final updatedMembers =
        family.memberUserIds.where((m) => m.userId != userId).toList();
    final updatedAdmins =
        family.adminUserIds.where((id) => id != userId).toList();

    if (family.adminUserIds.contains(userId) &&
        updatedAdmins.isEmpty &&
        updatedMembers.isNotEmpty) {
      debugPrint(
        'FamilyService: Error - Último administrador no puede salir.',
      );
      throw Exception('Cannot leave the family as the only administrator.');
    }

    final batch = _firestore.batch();
    batch.update(familyRef, {
      'memberUserIds': updatedMembers.map((m) => m.toFirestore()).toList(),
      'adminUserIds': updatedAdmins,
    });
    batch.update(_firestore.collection('users').doc(userId), {
      'familyIds': FieldValue.arrayRemove([familyId]),
    });

    try {
      await batch.commit();
      debugPrint('FamilyService: Usuario eliminado de la familia.');
    } catch (e) {
      debugPrint('FamilyService: Error al salir de la familia: $e');
      rethrow;
    }
  }
}
