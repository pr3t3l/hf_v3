// hf_v3/lib/features/family_structure/presentation/controllers/family_controller.dart

import 'package:hf_v3/features/family_structure/data/models/invitation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/family_structure/services/family_service.dart';
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as family_model; // Alias for your Family model

// Provider for FamilyController
final familyControllerProvider =
    StateNotifierProvider<FamilyController, AsyncValue<void>>((ref) {
      final familyService = ref.read(familyServiceProvider);
      return FamilyController(familyService);
    });

// Provider to stream the list of families the current user belongs to
final userFamiliesStreamProvider =
    StreamProvider.autoDispose<List<family_model.Family>>((ref) {
      // Use alias here
      final familyService = ref.watch(familyServiceProvider);
      return familyService.getUserFamiliesStream();
    });

// Provider to watch the currently active family
final activeFamilyProvider = StateProvider<family_model.Family?>(
  (ref) => null,
); // Use alias here

// NUEVO: Provider para obtener invitaciones pendientes de la familia activa
final pendingInvitationsStreamProvider =
    StreamProvider.autoDispose<List<Invitation>>((ref) {
      final familyService = ref.read(familyServiceProvider);
      final activeFamily = ref.watch(activeFamilyProvider);
      if (activeFamily == null) {
        // Retornar un stream vacío si no hay una familia activa
        return Stream.value([]);
      }
      return familyService.getFamilyPendingInvitationsStream(
        activeFamily.familyId,
      );
    });

class FamilyController extends StateNotifier<AsyncValue<void>> {
  final FamilyService _familyService;

  FamilyController(this._familyService) : super(const AsyncValue.data(null));

  // Modifica el método para que devuelva el ID de la familia.
  Future<String> createFamily(String familyName) async {
    state = const AsyncValue.loading();
    try {
      final newFamily = await _familyService.createFamily(familyName);
      state = const AsyncValue.data(null); // Success
      return newFamily.familyId; // Devuelve el ID de la familia
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> joinFamily(String invitationCode) async {
    state = const AsyncValue.loading();
    try {
      await _familyService.joinFamily(invitationCode);
      state = const AsyncValue.data(null); // Success
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> inviteMember(
    String familyId,
    String emailOrName, {
    required bool isRegisteredUser,
    bool isUnregisteredUserEmail = false,
    String? initialRole,
    String? initialRelationshipType,
    bool isDeceased = false,
    bool isPet = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _familyService.inviteMember(
        familyId,
        emailOrName,
        isRegisteredUser: isRegisteredUser,
        isUnregisteredUserEmail: isUnregisteredUserEmail,
        initialRole: initialRole,
        initialRelationshipType: initialRelationshipType,
        isDeceased: isDeceased,
        isPet: isPet,
      );
      state = const AsyncValue.data(null); // Success
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateMemberRole(
    String familyId,
    String memberUserId,
    String newRole,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _familyService.updateMemberRole(familyId, memberUserId, newRole);
      state = const AsyncValue.data(null); // Success
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removeUnregisteredMember(
    String familyId,
    String memberIdToRemove,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _familyService.removeUnregisteredMember(familyId, memberIdToRemove);
      state = const AsyncValue.data(null); // Success
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> leaveFamily(String familyId) async {
    state = const AsyncValue.loading();
    try {
      await _familyService.leaveFamily(familyId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
