class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final String role; // 'user' | 'admin'
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.role,
    required this.createdAt,
  });

  String get fullName => '$name $surname';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String,
      name: map['name'] as String,
      surname: map['surname'] as String,
      role: (map['role'] as String?) ?? 'user',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'surname': surname,
    'role': role,
    'createdAt': createdAt,
  };
}
