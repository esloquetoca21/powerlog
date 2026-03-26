// Colección Firestore: 'users'
enum UserRole { athlete, coach }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final double? bodyWeight; // kg
  final String? category;    // categoría de la federación
  final String? federation;  // ej. FEPE, IPF España
  final String? level;       // principiante, intermedio, competidor
  final DateTime? competitionDate;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = UserRole.athlete,
    this.bodyWeight,
    this.category,
    this.federation,
    this.level,
    this.competitionDate,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.athlete,
      ),
      bodyWeight: map['bodyWeight'] != null
          ? (map['bodyWeight'] as num).toDouble()
          : null,
      category: map['category'] as String?,
      federation: map['federation'] as String?,
      level: map['level'] as String?,
      competitionDate: map['competitionDate'] != null
          ? DateTime.parse(map['competitionDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'bodyWeight': bodyWeight,
      'category': category,
      'federation': federation,
      'level': level,
      'competitionDate': competitionDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
