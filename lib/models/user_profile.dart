class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String role; // 'user' | 'admin'

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.role,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=$id',
      role: map['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
    };
  }
}
