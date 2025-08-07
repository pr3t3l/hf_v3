// hf_v3/lib/features/family_structure/data/models/family_member.dart

class FamilyMember {
  final String userId;
  final String role; // e.g., 'parent', 'child', 'sibling', 'administrator'
  final String displayName;

  FamilyMember({
    required this.userId,
    required this.role,
    required this.displayName,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'userId': userId, 'role': role, 'displayName': displayName};
  }
}
