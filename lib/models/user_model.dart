// Colección Firestore: 'users'
enum UserRole { athlete, coach }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? gender;       // 'male' | 'female' | 'other'
  final double? bodyWeight;   // kg
  final String? category;     // categoría de la federación
  final String? federation;   // ej. FEPE, IPF España
  final String? level;        // principiante, intermedio, avanzado, competidor
  final DateTime? competitionDate;
  final bool onboardingCompleted;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = UserRole.athlete,
    this.gender,
    this.bodyWeight,
    this.category,
    this.federation,
    this.level,
    this.competitionDate,
    this.onboardingCompleted = false,
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? gender,
    double? bodyWeight,
    String? category,
    String? federation,
    String? level,
    DateTime? competitionDate,
    bool? onboardingCompleted,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      category: category ?? this.category,
      federation: federation ?? this.federation,
      level: level ?? this.level,
      competitionDate: competitionDate ?? this.competitionDate,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.athlete,
      ),
      gender: map['gender'] as String?,
      bodyWeight: map['bodyWeight'] != null
          ? (map['bodyWeight'] as num).toDouble()
          : null,
      category: map['category'] as String?,
      federation: map['federation'] as String?,
      level: map['level'] as String?,
      competitionDate: map['competitionDate'] != null
          ? DateTime.parse(map['competitionDate'] as String)
          : null,
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'gender': gender,
      'bodyWeight': bodyWeight,
      'category': category,
      'federation': federation,
      'level': level,
      'competitionDate': competitionDate?.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'timestamp': createdAt.toIso8601String(),
    };
  }
}
