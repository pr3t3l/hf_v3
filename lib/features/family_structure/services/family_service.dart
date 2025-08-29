// hf_v3/lib/features/family_structure/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  // ignore: unused_field
  final Uuid _uuid = const Uuid();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  FamilyService(this._firestore, this._firebaseAuth);

  // Helper to get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // --- Family Creation (Refactored) ---
  Future<family_model.Family> createFamily(String familyName) async {
    debugPrint('FamilyService: Iniciando createFamily para: $familyName');
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception("User not authenticated.");
    }
    debugPrint('FamilyService: Usuario autenticado: $userId');

    final currentUserDoc =
        await _firestore.collection('users').doc(userId).get();
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

    // La nueva familia ahora tiene un array de strings para memberUserIds
    final newFamily = family_model.Family(
      familyId: familyId,
      familyName: familyName,
      adminUserIds: [userId],
      memberUserIds: [userId], // Solo el UID del creador
      unregisteredMembers: [],
      usersPending: [],
      createdAt: Timestamp.now(),
      isActive: true,
    );
    debugPrint(
      'FamilyService: Objeto Family creado: ${newFamily.toFirestore()}',
    );

    final batch = _firestore.batch();

    // 1. Crear el documento principal de la familia
    batch.set(newFamilyRef, newFamily.toFirestore());
    debugPrint('FamilyService: Añadiendo creación de Family al batch.');

    // 2. Crear el documento del miembro en la subcolección /members
    final memberRef = newFamilyRef.collection('members').doc(userId);
    batch.set(memberRef, {
      'role': 'administrator', // El creador es administrador
      'displayName': currentUserProfile.displayName,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('FamilyService: Añadiendo creación de Member en subcolección.');

    // 3. Actualizar el perfil del usuario para añadir el familyId
    batch.update(_firestore.collection('users').doc(userId), {
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
    try {
      final HttpsCallable callable = _functions.httpsCallable('joinFamily');
      final result = await callable.call({'invitationCode': invitationCode});
      debugPrint(
        'FamilyService: Respuesta de Cloud Function joinFamily: ${result.data}',
      );
      if (result.data['status'] != 'success') {
        throw Exception(
          result.data['message'] ?? 'Error al unirse a la familia.',
        );
      }
      final String familyId = result.data['familyId'];
      final familyDoc =
          await _firestore.collection('families').doc(familyId).get();
      return family_model.Family.fromFirestore(familyDoc);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'FamilyService: Error de Cloud Function joinFamily: ${e.code} - ${e.message}',
      );
      throw Exception('Error al unirse a la familia: ${e.message}');
    } catch (e) {
      debugPrint('FamilyService: Error inesperado en joinFamily: $e');
      rethrow;
    }
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

  // --- NEW: Get Family Members Stream ---
  Stream<List<FamilyMember>> getFamilyMembersStream(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyMember(
          userId: doc.id,
          role: data['role'] ?? 'member',
          displayName: data['displayName'] ?? 'Unknown Member',
        );
      }).toList();
    });
  }

  // --- NEW: Get Single Family Member Stream ---
  Stream<FamilyMember> getFamilyMemberStream(
      String familyId, String memberId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception(
            'Member not found in family $familyId with id $memberId');
      }
      final data = doc.data()!;
      return FamilyMember(
        userId: doc.id,
        role: data['role'] ?? 'member',
        displayName: data['displayName'] ?? 'Unknown Member',
      );
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
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((
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
        final familyDoc =
            await _firestore.collection('families').doc(familyId).get();
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
          (snapshot) =>
              snapshot.docs.map((doc) => Invitation.fromFirestore(doc)).toList(),
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
      final familyDoc =
          await _firestore.collection('families').doc(familyId).get();
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

  // --- Get User Display Name by UID (Refactored) ---
  Future<String> getUserDisplayName(
    String userId, {
    String? familyId,
  }) async {
    debugPrint(
      'FamilyService: Obteniendo displayName para UID: $userId with familyId: $familyId',
    );
    try {
      // If familyId is provided, first try to get the name from the members subcollection.
      if (familyId != null) {
        final memberDoc = await _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .doc(userId)
            .get();
        if (memberDoc.exists && memberDoc.data()!.containsKey('displayName')) {
          return memberDoc.data()!['displayName'];
        }
      }
      // Fallback to the global users collection.
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserProfile.fromFirestore(userDoc).displayName;
      }
      debugPrint('FamilyService: Usuario no encontrado para UID: $userId');
      return 'Usuario Desconocido';
    } catch (e) {
      debugPrint(
        'FamilyService: Error al obtener displayName para UID $userId: $e',
      );
      return 'Usuario Desconocido';
    }
  }

  // --- NEW: Get a specific member's document from the subcollection ---
  Stream<FamilyMember> getMemberDocument(String familyId, String memberId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        throw Exception('Member document not found.');
      }
      return FamilyMember.fromFirestore(doc);
    });
  }

  // --- NEW: Get all members from the subcollection ---
  Stream<List<FamilyMember>> getFamilyMembersStream(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyMember.fromFirestore(doc))
            .toList());
  }

  // --- Assign/Modify Member Role (Refactored) ---
  Future<void> updateMemberRole(
    String familyId,
    String memberUserId,
    String newRole,
  ) async {
    debugPrint(
      'FamilyService: Iniciando updateMemberRole para familyId: $familyId, memberUserId: $memberUserId, newRole: $newRole',
    );
    final userId = currentUserId;
    if (userId == null) {
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

    // Only admins can update roles.
    if (!family.adminUserIds.contains(userId)) {
      throw Exception("Only family administrators can update member roles.");
    }

    // Directly update the document in the 'members' subcollection.
    final memberRef = familyRef.collection('members').doc(memberUserId);

    try {
      await memberRef.update({'role': newRole});
      debugPrint(
        'FamilyService: Rol de miembro actualizado directamente en la subcolección.',
      );
    } catch (e) {
      debugPrint(
        'FamilyService: Error al actualizar rol de miembro en subcolección: $e',
      );
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
        'unregisteredMembers':
            updatedUnregisteredMembers.map((m) => m.toFirestore()).toList(),
      });
      debugPrint(
        'FamilyService: Miembro no registrado eliminado en Firestore.',
      );
    } catch (e) {
      debugPrint('FamilyService: Error al eliminar miembro no registrado: $e');
      rethrow;
    }
  }

  // --- Leave Family (Refactored with Transaction) ---
  Future<void> leaveFamily(String familyId) async {
    debugPrint('FamilyService: Iniciando leaveFamily para familyId: $familyId');
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('FamilyService: Error - Usuario no autenticado.');
      throw Exception('User not authenticated.');
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final userRef = _firestore.collection('users').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final familyDoc = await transaction.get(familyRef);
        if (!familyDoc.exists) {
          throw Exception('Family not found.');
        }

        final family = family_model.Family.fromFirestore(familyDoc);

        if (!family.memberUserIds.contains(userId)) {
          throw Exception('User is not a member of this family.');
        }

        // Atomically check if the user is the last admin.
        final bool isLastAdmin = family.adminUserIds.contains(userId) &&
            family.adminUserIds.length == 1;
        final bool hasOtherMembers = family.memberUserIds.length > 1;

        if (isLastAdmin && hasOtherMembers) {
          throw Exception('Cannot leave the family as the only administrator.');
        }

        // 1. Update the family document.
        transaction.update(familyRef, {
          'memberUserIds': FieldValue.arrayRemove([userId]),
          'adminUserIds': FieldValue.arrayRemove([userId]),
        });

        // 2. Delete the member document from the subcollection.
        final memberRef = familyRef.collection('members').doc(userId);
        transaction.delete(memberRef);

        // 3. Update the user's profile.
        transaction.update(userRef, {
          'familyIds': FieldValue.arrayRemove([familyId]),
        });
      });
      debugPrint('FamilyService: Usuario eliminado de la familia con éxito.');
    } catch (e) {
      debugPrint('FamilyService: Error al salir de la familia: $e');
      rethrow;
    }
  }
}
