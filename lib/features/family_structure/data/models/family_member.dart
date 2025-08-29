import 'package:cloud_firestore/cloud_firestore.dart';

// Represents the data for a registered member, fetched from the /families/{familyId}/members/{userId} subcollection.
// This is primarily a UI/service-layer model.
class FamilyMember {
  final String userId;
  final String role;
  final String displayName;

  FamilyMember({
    required this.userId,
    required this.role,
    required this.displayName,
  });

  factory FamilyMember.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FamilyMember(
      userId: doc.id,
      role: data['role'] ?? 'member',
      displayName: data['displayName'] ?? 'Unknown Member',
    );
  }
}
