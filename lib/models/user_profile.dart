class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String role;
  String ward; // <-- NEW: Neighborhood Network anchor

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.role,
    this.ward = 'J.P. Nagar',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'ward': ward,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      role: map['role'] ?? 'user',
      ward: map['ward'] ?? 'J.P. Nagar',
    );
  }
}