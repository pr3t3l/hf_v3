// hf_v3/lib/features/family_structure/data/models/family.dart

// hf_v3/lib/features/family_structure/data/models/family.dart

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hf_v3/features/family_structure/data/models/family_member.dart'; // No longer needed
import 'package:hf_v3/features/family_structure/data/models/unregistered_member.dart';

class Family {
  final String familyId;
  final String familyName;
  final List<String> adminUserIds; // List of user UIDs who are admins
  final List<String>
      memberUserIds; // List of registered user UIDs in the family
  final List<UnregisteredMember>
      unregisteredMembers; // List of non-registered members
  final List<String> usersPending; // UIDs of invited users pending acceptance
  final Timestamp createdAt;
  final bool isActive;

  Family({
    required this.familyId,
    required this.familyName,
    required this.adminUserIds,
    required this.memberUserIds,
    required this.unregisteredMembers,
    required this.usersPending,
    required this.createdAt,
    required this.isActive,
  });

  factory Family.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Family(
      familyId: doc.id,
      familyName: data['familyName'] ?? '',
      adminUserIds: List<String>.from(data['adminUserIds'] ?? []),
      memberUserIds: List<String>.from(
        data['memberUserIds'] ?? [],
      ), // Changed to List<String>
      unregisteredMembers: (data['unregisteredMembers'] as List<dynamic>?)
              ?.map(
                (m) => UnregisteredMember.fromMap(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
      usersPending: List<String>.from(data['usersPending'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'adminUserIds': adminUserIds,
      'memberUserIds': memberUserIds, // Changed to store as List<String>
      'unregisteredMembers':
          unregisteredMembers.map((m) => m.toFirestore()).toList(),
      'usersPending': usersPending,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
