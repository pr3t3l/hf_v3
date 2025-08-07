// hf_v3/lib/features/family_structure/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

// Common models
import 'package:hf_v3/common/models/user_profile.dart'; // UserProfile model

// Family Structure specific models
import 'package:hf_v3/features/family_structure/data/models/family.dart'
    as FamilyModel; // Alias for your Family model
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
  Future<FamilyModel.Family> createFamily(String familyName) async {
    // Use alias here
    if (currentUserId == null) {
      throw Exception("User not authenticated.");
    }

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    if (!currentUserDoc.exists) {
      throw Exception("Current user profile not found.");
    }
    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);

    final newFamilyRef = _firestore
        .collection('families')
        .doc(); // Firestore generates ID
    final familyId = newFamilyRef.id;

    final newFamily = FamilyModel.Family(
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

    // Use a Firestore batch to ensure atomicity
    final batch = _firestore.batch();

    // 1. Create the family document
    batch.set(newFamilyRef, newFamily.toFirestore());

    // 2. Add familyId to creator's user profile
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'familyIds': FieldValue.arrayUnion([familyId]),
    });

    await batch.commit();
    return newFamily;
  }

  // --- Join Family ---
  Future<FamilyModel.Family> joinFamily(String invitationCode) async {
    // Use alias here
    if (currentUserId == null) {
      throw Exception("User not authenticated.");
    }

    final invitationsQuery = await _firestore
        .collection('invitations')
        .where('invitationCode', isEqualTo: invitationCode)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (invitationsQuery.docs.isEmpty) {
      throw Exception("Invalid or expired invitation code.");
    }

    final invitationDoc = invitationsQuery.docs.first;
    final invitation = Invitation.fromFirestore(invitationDoc);

    final familyRef = _firestore
        .collection('families')
        .doc(invitation.familyId);
    final familyDoc = await familyRef.get();

    if (!familyDoc.exists) {
      throw Exception("Family does not exist.");
    }

    final family = FamilyModel.Family.fromFirestore(
      familyDoc,
    ); // Use alias here

    // Check if user is already a member
    if (family.memberUserIds.any((member) => member.userId == currentUserId)) {
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

    // 2. Add familyId to user's profile
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'familyIds': FieldValue.arrayUnion([invitation.familyId]),
    });

    // 3. Update invitation status
    batch.update(invitationDoc.reference, {'status': 'accepted'});

    // 4. Create initial family relationship between inviter and invited
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
    }

    await batch.commit();
    return FamilyModel.Family.fromFirestore(
      await familyRef.get(),
    ); // Use alias here
  }

  // --- NEW: Fetch Invitation by Code ---
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
    if (currentUserId == null) {
      throw Exception("User not authenticated.");
    }

    final familyDoc = await _firestore
        .collection('families')
        .doc(familyId)
        .get();
    if (!familyDoc.exists) {
      throw Exception("Family not found.");
    }
    final family = FamilyModel.Family.fromFirestore(
      familyDoc,
    ); // Use alias here

    // Only admins can invite
    if (!family.adminUserIds.contains(currentUserId)) {
      throw Exception("Only family administrators can invite members.");
    }

    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final currentUserProfile = UserProfile.fromFirestore(currentUserDoc);

    if (isRegisteredUser) {
      // --- Invite existing registered user by email ---
      final invitedUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailOrName)
          .limit(1)
          .get();

      if (invitedUserQuery.docs.isEmpty) {
        throw Exception("No registered user found with this email.");
      }
      final invitedUserId = invitedUserQuery.docs.first.id;
      final invitedUserProfile = UserProfile.fromFirestore(
        invitedUserQuery.docs.first,
      ); // This variable is unused, can be removed if not needed for future logic

      // Check if already a member
      if (family.memberUserIds.any(
        (member) => member.userId == invitedUserId,
      )) {
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
      // print("Invitation created for ${invitation.invitedEmail} with code: ${invitation.invitationCode}"); // Removed print
    } else {
      // --- Add unregistered member by name (can be deceased/pet) ---
      // Check if a non-registered member with this name already exists in the family
      if (family.unregisteredMembers.any(
        (member) =>
            member.name == emailOrName &&
            member.isDeceased == isDeceased &&
            member.isPet == isPet,
      )) {
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
      }
    }
  }

  // --- Fetch Family Details ---
  Stream<FamilyModel.Family> getFamilyStream(String familyId) {
    // Use alias here
    return _firestore.collection('families').doc(familyId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        throw Exception("Family not found.");
      }
      return FamilyModel.Family.fromFirestore(snapshot); // Use alias here
    });
  }

  // --- Fetch User's Families ---
  Stream<List<FamilyModel.Family>> getUserFamiliesStream() {
    // Use alias here
    if (currentUserId == null) {
      return Stream.value([]); // Return empty list if not authenticated
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userSnapshot) async {
          if (!userSnapshot.exists) {
            return [];
          }
          final userProfile = UserProfile.fromFirestore(userSnapshot);
          if (userProfile.familyIds.isEmpty) {
            return [];
          }

          final families = <FamilyModel.Family>[]; // Use alias here
          for (final familyId in userProfile.familyIds) {
            final familyDoc = await _firestore
                .collection('families')
                .doc(familyId)
                .get();
            if (familyDoc.exists) {
              families.add(
                FamilyModel.Family.fromFirestore(familyDoc),
              ); // Use alias here
            }
          }
          return families;
        });
  }

  // --- Assign/Modify Member Role ---
  Future<void> updateMemberRole(
    String familyId,
    String memberUserId,
    String newRole,
  ) async {
    if (currentUserId == null) {
      throw Exception("User not authenticated.");
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final familyDoc = await familyRef.get();
    if (!familyDoc.exists) {
      throw Exception("Family not found.");
    }
    final family = FamilyModel.Family.fromFirestore(
      familyDoc,
    ); // Use alias here

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

    await familyRef.update({
      'memberUserIds': updatedMembers.map((m) => m.toFirestore()).toList(),
    });
  }

  // --- Remove Unregistered Member ---
  Future<void> removeUnregisteredMember(
    String familyId,
    String memberIdToRemove,
  ) async {
    if (currentUserId == null) {
      throw Exception("User not authenticated.");
    }

    final familyRef = _firestore.collection('families').doc(familyId);
    final familyDoc = await familyRef.get();
    if (!familyDoc.exists) {
      throw Exception("Family not found.");
    }
    final family = FamilyModel.Family.fromFirestore(
      familyDoc,
    ); // Use alias here

    // Only admins can remove unregistered members
    if (!family.adminUserIds.contains(currentUserId)) {
      throw Exception("Only family administrators can remove members.");
    }

    final updatedUnregisteredMembers = family.unregisteredMembers
        .where((member) => member.memberId != memberIdToRemove)
        .toList();

    await familyRef.update({
      'unregisteredMembers': updatedUnregisteredMembers
          .map((m) => m.toFirestore())
          .toList(),
    });
  }
}
