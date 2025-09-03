import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import 'package:hf_v3/common/models/user_profile.dart';
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
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  // ignore: unused_field
  final Uuid _uuid = const Uuid();

  FamilyService(this._firestore, this._firebaseAuth);

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // --- Family Creation (Refactored) ---
  Future<family_model.Family> createFamily(String familyName) async {
    final userId = currentUserId;
    if (userId == null) throw Exception("User not authenticated.");

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    if (!currentUserDoc.exists)
      throw Exception("Current user profile not found.");

    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);
    final newFamilyRef = _firestore.collection('families').doc();
    final familyId = newFamilyRef.id;

    final newFamily = family_model.Family(
      familyId: familyId,
      familyName: familyName,
      adminUserIds: [userId],
      memberUserIds: [userId],
      unregisteredMembers: [],
      usersPending: [],
      createdAt: Timestamp.now(),
      isActive: true,
    );

    final batch = _firestore.batch();
    batch.set(newFamilyRef, newFamily.toFirestore());

    final memberRef = newFamilyRef.collection('members').doc(userId);
    batch.set(memberRef, {
      'role': 'administrator',
      'displayName': currentUserProfile.displayName,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_firestore.collection('users').doc(userId), {
      'familyIds': FieldValue.arrayUnion([familyId]),
    });

    await batch.commit();
    return newFamily;
  }

  // --- Join Family (Calls Cloud Function) ---
  Future<family_model.Family> joinFamily(String invitationCode) async {
    if (currentUserId == null) throw Exception("User not authenticated.");

    final HttpsCallable callable = _functions.httpsCallable('joinFamily');
    final result = await callable.call({'invitationCode': invitationCode});

    if (result.data['status'] != 'success') {
      throw Exception(result.data['message'] ?? 'Error joining family.');
    }

    final String familyId = result.data['familyId'];
    final familyDoc = await _firestore
        .collection('families')
        .doc(familyId)
        .get();
    return family_model.Family.fromFirestore(familyDoc);
  }

  // --- Invite Members (Calls Cloud Function) ---
  Future<void> inviteMember(
    String familyId,
    String emailOrName, {
    required bool isRegisteredUser,
    String? initialRole,
    String? initialRelationshipType,
    bool isDeceased = false,
    bool isPet = false,
  }) async {
    await _functions.httpsCallable('inviteFamilyMember').call({
      'familyId': familyId,
      'emailOrName': emailOrName,
      'isRegisteredUser': isRegisteredUser,
      'initialRole': initialRole,
      'initialRelationshipType': initialRelationshipType,
      'isDeceased': isDeceased,
      'isPet': isPet,
    });
  }

  // --- Data Fetching ---
  Stream<family_model.Family> getFamilyStream(String familyId) {
    return _firestore.collection('families').doc(familyId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) throw Exception("Family not found.");
      return family_model.Family.fromFirestore(snapshot);
    });
  }

  Stream<List<family_model.Family>> getUserFamiliesStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userSnapshot) async {
          if (!userSnapshot.exists) return [];
          final userProfile = UserProfile.fromFirestore(userSnapshot);
          if (userProfile.familyIds.isEmpty) return [];

          final familyDocs = await Future.wait(
            userProfile.familyIds.map(
              (id) => _firestore.collection('families').doc(id).get(),
            ),
          );
          return familyDocs
              .where((doc) => doc.exists)
              .map((doc) => family_model.Family.fromFirestore(doc))
              .toList();
        });
  }

  // Nuevo método: Obtener invitaciones pendientes de una familia
  Stream<List<Invitation>> getFamilyPendingInvitationsStream(String familyId) {
    return _firestore
        .collection('invitations')
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => Invitation.fromFirestore(d)).toList());
  }

  Stream<List<Invitation>> getPendingInvitationsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('invitations')
        .where('invitedUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => Invitation.fromFirestore(d)).toList());
  }

  Future<Invitation?> getInvitationByCode(String invitationCode) async {
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('invitationCode', isEqualTo: invitationCode)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Invitation.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  Future<String> getFamilyName(String familyId) async {
    try {
      final familyDoc = await _firestore
          .collection('families')
          .doc(familyId)
          .get();
      if (familyDoc.exists) {
        return family_model.Family.fromFirestore(familyDoc).familyName;
      }
      return 'Unknown Family';
    } catch (e) {
      return 'Error loading name';
    }
  }

  // --- NEW: Member Subcollection Methods ---
  Stream<List<FamilyMember>> getFamilyMembersStream(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .map((s) => s.docs.map((d) => FamilyMember.fromFirestore(d)).toList());
  }

  Stream<FamilyMember> getMemberDocument(String familyId, String memberId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((d) {
          if (!d.exists) throw Exception('Member document not found.');
          return FamilyMember.fromFirestore(d);
        });
  }

  Future<String> getUserDisplayName(String userId, {String? familyId}) async {
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
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.exists
        ? UserProfile.fromFirestore(userDoc).displayName
        : 'Unknown User';
  }

  // --- Member Actions (Refactored) ---
  Future<void> updateMemberRole(
    String familyId,
    String memberUserId,
    String newRole,
  ) async {
    final familyRef = _firestore.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(memberUserId);
    await memberRef.update({'role': newRole});
  }

  Future<void> removeUnregisteredMember(
    String familyId,
    String memberIdToRemove,
  ) async {
    final familyRef = _firestore.collection('families').doc(familyId);
    final familyDoc = await familyRef.get();
    if (!familyDoc.exists) throw Exception("Family not found.");

    final family = family_model.Family.fromFirestore(familyDoc);
    final updatedUnregisteredMembers = family.unregisteredMembers
        .where((m) => m.memberId != memberIdToRemove)
        .toList();

    await familyRef.update({
      'unregisteredMembers': updatedUnregisteredMembers
          .map((m) => m.toFirestore())
          .toList(),
    });
  }

  Future<void> leaveFamily(String familyId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated.');

    final familyRef = _firestore.collection('families').doc(familyId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final familyDoc = await transaction.get(familyRef);
      if (!familyDoc.exists) throw Exception('Family not found.');

      final family = family_model.Family.fromFirestore(familyDoc);
      if (!family.memberUserIds.contains(userId))
        throw Exception('User is not a member of this family.');

      final bool isLastAdmin =
          family.adminUserIds.contains(userId) &&
          family.adminUserIds.length == 1;
      if (isLastAdmin && family.memberUserIds.length > 1) {
        throw Exception('Cannot leave the family as the only administrator.');
      }

      transaction.update(familyRef, {
        'memberUserIds': FieldValue.arrayRemove([userId]),
        'adminUserIds': FieldValue.arrayRemove([userId]),
      });

      final memberRef = familyRef.collection('members').doc(userId);
      transaction.delete(memberRef);
      transaction.update(userRef, {
        'familyIds': FieldValue.arrayRemove([familyId]),
      });
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    if (currentUserId == null) throw Exception("User not authenticated.");
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'declined',
    });
  }
}
