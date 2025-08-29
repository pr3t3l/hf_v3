// hf_v3/lib/features/family_structure/data/models/family.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hf_v3/features/family_structure/data/models/unregistered_member.dart';

class Family {
  final String familyId;
  final String familyName;
  final List<String> adminUserIds;
  final List<String> memberUserIds; // Now a list of user IDs (strings)
  final List<UnregisteredMember> unregisteredMembers;
  final List<String> usersPending;
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
      memberUserIds: List<String>.from(data['memberUserIds'] ?? []),
      unregisteredMembers: (data['unregisteredMembers'] as List<dynamic>?)
          ?.map((m) => UnregisteredMember.fromMap(m as Map<String, dynamic>))
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
      'memberUserIds': memberUserIds,
      'unregisteredMembers':
          unregisteredMembers.map((m) => m.toFirestore()).toList(),
      'usersPending': usersPending,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
