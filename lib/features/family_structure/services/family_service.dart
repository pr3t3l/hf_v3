// hf_v3/lib/features/family_structure/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:flutter/foundation.dart'; // Import this for debugPrint

// Common models
import 'package:hf_v3/common/models/user_profile.dart'; // UserProfile model

// Family Structure specific models
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as family_model; // Alias changed to lower_case_with_underscores
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/data/models/invitation.dart';
import 'package:hf_v3/features/family_structure/data/models/unregistered_member.dart';

final familyServiceProvider = Provider<FamilyService>(
  (ref) => FamilyService(FirebaseFirestore.instance, FirebaseAuth.instance),
);

class FamilyService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final Uuid _uuid = const Uuid(); // Initialize UUID generator

  FamilyService(this._firestore, this._firebaseAuth);

  // Helper to get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // --- Family Creation ---
  Future<family_model.Family> createFamily(String familyName) async {
    // Use alias here
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

    final newFamilyRef = _firestore
        .collection('families')
        .doc(); // Firestore generates ID
    final familyId = newFamilyRef.id;
    debugPrint('FamilyService: Generando nuevo Family ID: $familyId');

    final newFamily = family_model.Family(
      // Use alias here
      familyId: familyId,
      familyName: familyName,
      adminUserIds: [currentUserId!], // Creator is the first admin
      memberUserIds: [
        FamilyMember(
          userId: currentUserId!,
          role: 'parent', // Default role for creator
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

    // Use a Firestore batch to ensure atomicity
    final batch = _firestore.batch();

    // 1. Create the family document
    batch.set(newFamilyRef, newFamily.toFirestore());
    debugPrint('FamilyService: Añadiendo creación de Family al batch.');

    // 2. Add familyId to creator's user profile
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
      rethrow; // Re-lanza la excepción para que la UI la capture
    }
    return newFamily;
  }

  // --- Join Family ---
  Future<family_model.Family> joinFamily(String invitationCode) async {
    // Use alias here
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

    final family = family_model.Family.fromFirestore(
      familyDoc,
    ); // Use alias here
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
      debugPrint(
        'FamilyService: Error - Perfil de usuario actual no encontrado.',
      );
      throw Exception("Current user profile not found.");
    }
    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);
    debugPrint(
      'FamilyService: Perfil de usuario actual cargado: ${currentUserProfile.displayName}',
    );

    // Use a Firestore batch for atomic updates
    final batch = _firestore.batch();

    // 1. Add user to family's memberUserIds
    batch.update(familyRef, {
      'memberUserIds': FieldValue.arrayUnion([
        FamilyMember(
          userId: currentUserId!,
          role:
              invitation.initialRole ??
              'child', // Use role from invitation, default to 'child'
          displayName: currentUserProfile
              .displayName, // Use user's registered display name
        ).toFirestore(),
      ]),
    });
    debugPrint('FamilyService: Añadiendo usuario a memberUserIds del batch.');

    // 2. Add familyId to user's profile
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'familyIds': FieldValue.arrayUnion([invitation.familyId]),
    });
    debugPrint('FamilyService: Añadiendo familyId a user profile del batch.');

    // 3. Update invitation status
    batch.update(invitationDoc.reference, {'status': 'accepted'});
    debugPrint(
      'FamilyService: Actualizando estado de invitación a aceptada en el batch.',
    );

    // 4. Create initial family relationship between inviter and invited
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
          'dynamicType': 'initial_connection', // Default for new relationships
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
    return family_model.Family.fromFirestore(
      await familyRef.get(),
    ); // Fetch updated family // Use alias here
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

  // --- Invite Members ---
  // isRegisteredUser: true if inviting by email to a registered user
  // isRegisteredUser: false if adding an unregistered person (by name, can be deceased/pet)
  Future<void> inviteMember(
    String familyId,
    String emailOrName, {
    required bool isRegisteredUser,
    String? initialRole, // Role for registered user if invited
    String?
    initialRelationshipType, // Relationship for both registered and unregistered
    bool isDeceased = false, // For unregistered members
    bool isPet = false, // For unregistered members
  }) async {
    debugPrint(
      'FamilyService: Iniciando inviteMember para familyId: $familyId, emailOrName: $emailOrName',
    );
    if (currentUserId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception("User not authenticated.");
    }

    final familyDoc = await _firestore
        .collection('families')
        .doc(familyId)
        .get();
    if (!familyDoc.exists) {
      debugPrint('FamilyService: Error - Familia no encontrada.');
      throw Exception("Family not found.");
    }
    final family = family_model.Family.fromFirestore(
      familyDoc,
    ); // Use alias here
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    // Only admins can invite
    if (!family.adminUserIds.contains(currentUserId)) {
      debugPrint('FamilyService: Error - Usuario no es administrador.');
      throw Exception("Only family administrators can invite members.");
    }

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);
    debugPrint(
      'FamilyService: Perfil de usuario actual cargado: ${currentUserProfile.displayName}',
    );

    if (isRegisteredUser) {
      // --- Invite existing registered user by email ---
      debugPrint(
        'FamilyService: Invitando usuario registrado por email: $emailOrName',
      );
      final invitedUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailOrName)
          .limit(1)
          .get();

      if (invitedUserQuery.docs.isEmpty) {
        debugPrint(
          'FamilyService: No se encontró usuario registrado con este email.',
        );
        throw Exception("No registered user found with this email.");
      }
      final invitedUserId = invitedUserQuery.docs.first.id;
      // final invitedUserProfile = UserProfile.fromFirestore(invitedUserQuery.docs.first); // This variable is unused, can be removed if not needed for future logic

      // Check if already a member
      if (family.memberUserIds.any(
        (member) => member.userId == invitedUserId,
      )) {
        debugPrint(
          'FamilyService: Error - Usuario ya es miembro de la familia.',
        );
        throw Exception("This user is already a member of the family.");
      }

      // Check for pending invitation to avoid duplicates
      final existingInvitation = await _firestore
          .collection('invitations')
          .where('familyId', isEqualTo: familyId)
          .where('invitedUserId', isEqualTo: invitedUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        debugPrint(
          'FamilyService: Ya existe una invitación pendiente para este usuario.',
        );
        throw Exception(
          "There is already a pending invitation for this user to this family.",
        );
      }

      // Create invitation
      final invitation = Invitation(
        invitationId: _uuid.v4(), // Generate unique ID
        familyId: familyId,
        invitedByUserId: currentUserId!,
        invitedByDisplayName:
            currentUserProfile.displayName, // Store inviter's display name
        invitedEmail: emailOrName,
        invitedUserId: invitedUserId, // Store invited user's UID
        initialRole: initialRole, // Pass role from inviter
        initialRelationshipType:
            initialRelationshipType, // Pass relationship from inviter
        status: 'pending',
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ), // Corrected Timestamp.fromDate
        invitationCode: _uuid.v4().substring(0, 8).toUpperCase(), // Short code
      );
      await _firestore
          .collection('invitations')
          .doc(invitation.invitationId)
          .set(invitation.toFirestore());

      // TODO: Trigger Cloud Function to send email notification to invitedEmail
      // debugPrint("Invitation created for ${invitation.invitedEmail} with code: ${invitation.invitationCode}"); // Removed print
    } else {
      // --- Add unregistered member by name (can be deceased/pet) ---
      debugPrint(
        'FamilyService: Añadiendo miembro no registrado: $emailOrName',
      );
      // Check if a non-registered member with this name already exists in the family
      if (family.unregisteredMembers.any(
        (member) =>
            member.name == emailOrName &&
            member.isDeceased == isDeceased &&
            member.isPet == isPet,
      )) {
        debugPrint(
          'FamilyService: Miembro no registrado con este nombre y tipo ya existe.',
        );
        throw Exception(
          "A non-registered member with this name and type already exists in the family.",
        );
      }

      final unregisteredMember = UnregisteredMember(
        memberId: _uuid.v4(), // Generate unique ID for unregistered member
        name: emailOrName,
        relationship:
            initialRelationshipType ??
            'other', // Use provided relationship, default to 'other'
        profileData: {}, // Initial empty profile data for IA
        isDeceased: isDeceased, // New field
        isPet: isPet, // New field
      );

      // Add unregistered member to the family document
      await _firestore.collection('families').doc(familyId).update({
        'unregisteredMembers': FieldValue.arrayUnion([
          unregisteredMember.toFirestore(),
        ]),
      });
      debugPrint('FamilyService: Miembro no registrado añadido a la familia.');

      // Create initial family relationship between inviter and the new unregistered member
      if (initialRelationshipType != null) {
        final relationshipId = _uuid.v4();
        await _firestore
            .collection('familyRelationships')
            .doc(relationshipId)
            .set({
              'familyId': familyId,
              'member1Ref': {'type': 'user', 'id': currentUserId},
              'member2Ref': {
                'type': 'unregisteredMember',
                'id': unregisteredMember.memberId,
              },
              'relationshipType': initialRelationshipType,
              'dynamicType': 'initial_connection',
              'description':
                  'Relación establecida al añadir miembro no registrado.',
              'frequency': 0.0,
              'lastInteraction': Timestamp.now(),
              'patterns': [],
              'iaConfidenceScore': 0.0,
              'interactionCount': 0,
            });
        debugPrint(
          'FamilyService: Relación para miembro no registrado creada.',
        );
      }
    }
  }

  // --- Fetch Family Details ---
  Stream<family_model.Family> getFamilyStream(String familyId) {
    // Use alias here
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
      return family_model.Family.fromFirestore(snapshot); // Use alias here
    });
  }

  // --- Fetch User's Families ---
  Stream<List<family_model.Family>> getUserFamiliesStream() {
    // Use alias here
    debugPrint(
      'FamilyService: Obteniendo stream de familias del usuario actual.',
    );
    if (currentUserId == null) {
      debugPrint(
        'FamilyService: Usuario no autenticado, retornando stream vacío.',
      );
      return Stream.value([]); // Return empty list if not authenticated
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

      final families = <family_model.Family>[]; // Use alias here
      debugPrint(
        'FamilyService: Cargando ${userProfile.familyIds.length} familias del usuario.',
      );
      for (final familyId in userProfile.familyIds) {
        final familyDoc = await _firestore
            .collection('families')
            .doc(familyId)
            .get();
        if (familyDoc.exists) {
          families.add(
            family_model.Family.fromFirestore(familyDoc),
          ); // Use alias here
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
        ).familyName; // Use alias
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
    final family = family_model.Family.fromFirestore(
      familyDoc,
    ); // Use alias here
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    // Only admins can update roles
    if (!family.adminUserIds.contains(currentUserId)) {
      debugPrint('FamilyService: Error - Usuario no es administrador.');
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
    final family = family_model.Family.fromFirestore(
      familyDoc,
    ); // Use alias here
    debugPrint('FamilyService: Familia cargada: ${family.familyName}');

    // Only admins can remove unregistered members
    if (!family.adminUserIds.contains(currentUserId)) {
      debugPrint('FamilyService: Error - Usuario no es administrador.');
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
}
