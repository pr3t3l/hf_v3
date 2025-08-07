// hf_v3/lib/features/family_structure/data/models/family.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hf_v3/features/family_structure/data/models/family_member.dart';
import 'package:hf_v3/features/family_structure/data/models/unregistered_member.dart';

class Family {
  final String familyId;
  final String familyName;
  final List<String> adminUserIds; // List of user UIDs who are admins
  final List<FamilyMember>
  memberUserIds; // List of registered users in the family
  final List<UnregisteredMember>
  unregisteredMembers; // List of non-registered members
  final Timestamp createdAt;
  final bool isActive;

  Family({
    required this.familyId,
    required this.familyName,
    required this.adminUserIds,
    required this.memberUserIds,
    required this.unregisteredMembers,
    required this.createdAt,
    required this.isActive,
  });

  factory Family.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Family(
      familyId: doc.id,
      familyName: data['familyName'] ?? '',
      adminUserIds: List<String>.from(data['adminUserIds'] ?? []),
      memberUserIds:
          (data['memberUserIds'] as List<dynamic>?)
              ?.map((m) => FamilyMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      unregisteredMembers:
          (data['unregisteredMembers'] as List<dynamic>?)
              ?.map(
                (m) => UnregisteredMember.fromMap(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'adminUserIds': adminUserIds,
      'memberUserIds': memberUserIds.map((m) => m.toFirestore()).toList(),
      'unregisteredMembers': unregisteredMembers
          .map((m) => m.toFirestore())
          .toList(),
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
