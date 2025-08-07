import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String displayName;
  final Timestamp createdAt;
  final Timestamp lastLogin;
  final String preferredLanguage;
  final List<String> familyIds;
  final Map<String, dynamic>
  profileData; // Store personality traits, emotional triggers, interests

  UserProfile({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.createdAt,
    required this.lastLogin,
    required this.preferredLanguage,
    required this.familyIds,
    required this.profileData,
  });

  // Factory constructor to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserProfile(
      userId: doc.id, // Document ID is the userId
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastLogin: data['lastLogin'] ?? Timestamp.now(),
      preferredLanguage: data['preferredLanguage'] ?? 'es',
      familyIds: List<String>.from(data['familyIds'] ?? []),
      profileData: Map<String, dynamic>.from(data['profileData'] ?? {}),
    );
  }

  // Method to convert UserProfile to a Firestore-compatible Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'preferredLanguage': preferredLanguage,
      'familyIds': familyIds,
      'profileData': profileData,
    };
  }

  // Method to create an initial UserProfile for new registrations
  static UserProfile initial({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
  }) {
    return UserProfile(
      userId: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      displayName: '$firstName $lastName',
      createdAt: Timestamp.now(),
      lastLogin: Timestamp.now(),
      preferredLanguage: 'es', // Default language
      familyIds: [],
      profileData: {}, // Empty profile data for IA to populate
    );
  }
}
