// hf_v3/lib/features/family_structure/data/models/unregistered_member.dart

class UnregisteredMember {
  final String memberId; // Unique ID for this unregistered member
  final String name;
  final String
  relationship; // e.g., 'abuela', 'primo', 'tío', 'mascota', 'fallecido'
  final Map<String, dynamic> profileData; // IA profile data for this member
  final bool isDeceased; // Indicates if the member is deceased
  final bool isPet; // Indicates if the member is a pet

  UnregisteredMember({
    required this.memberId,
    required this.name,
    required this.relationship,
    required this.profileData,
    this.isDeceased = false, // Default to false
    this.isPet = false, // Default to false
  });

  factory UnregisteredMember.fromMap(Map<String, dynamic> map) {
    return UnregisteredMember(
      memberId: map['memberId'] ?? '',
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      profileData: Map<String, dynamic>.from(map['profileData'] ?? {}),
      isDeceased: map['isDeceased'] ?? false,
      isPet: map['isPet'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'name': name,
      'relationship': relationship,
      'profileData': profileData,
      'isDeceased': isDeceased,
      'isPet': isPet,
    };
  }
}
