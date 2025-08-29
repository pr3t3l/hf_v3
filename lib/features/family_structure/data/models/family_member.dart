import 'package:cloud_firestore/cloud_firestore.dart';

// Represents the data for a registered member, stored in the /families/{familyId}/members/{userId} subcollection.
class FamilyMember {
  final String userId;
  final String role;
  final String displayName;

  FamilyMember({
    required this.userId,
    required this.role,
    required this.displayName,
  });

  // Creates a FamilyMember from a Firestore document snapshot.
  factory FamilyMember.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FamilyMember(
      userId: doc.id,
      role: data['role'] ?? 'member', // Default role to 'member'
      displayName: data['displayName'] ?? 'Unknown Member',
    );
  }
}
