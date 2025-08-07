// hf_v3/lib/features/family_structure/data/models/invitation.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Invitation {
  final String invitationId;
  final String familyId;
  final String invitedByUserId;
  final String invitedByDisplayName; // Display name of the inviter
  final String invitedEmail; // Email of the invited user
  final String? invitedUserId; // UID if the invited user is already registered
  final String? initialRole; // Suggested role for the invited user upon joining
  final String?
  initialRelationshipType; // Suggested relationship type for the invited user
  final String status; // 'pending', 'accepted', 'declined', 'expired'
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final String invitationCode;

  Invitation({
    required this.invitationId,
    required this.familyId,
    required this.invitedByUserId,
    required this.invitedByDisplayName,
    required this.invitedEmail,
    this.invitedUserId,
    this.initialRole,
    this.initialRelationshipType,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.invitationCode,
  });

  factory Invitation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Invitation(
      invitationId: doc.id,
      familyId: data['familyId'] ?? '',
      invitedByUserId: data['invitedByUserId'] ?? '',
      invitedByDisplayName: data['invitedByDisplayName'] ?? '',
      invitedEmail: data['invitedEmail'] ?? '',
      invitedUserId: data['invitedUserId'],
      initialRole: data['initialRole'],
      initialRelationshipType: data['initialRelationshipType'],
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      invitationCode: data['invitationCode'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'invitedByUserId': invitedByUserId,
      'invitedByDisplayName': invitedByDisplayName,
      'invitedEmail': invitedEmail,
      'invitedUserId': invitedUserId,
      'initialRole': initialRole,
      'initialRelationshipType': initialRelationshipType,
      'status': status,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'invitationCode': invitationCode,
    };
  }
}
