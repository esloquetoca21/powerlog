/// Preferencias del usuario para un ejercicio concreto.
/// Firestore: users/{uid}/exercise_prefs/{exerciseId}
class ExercisePref {
  final String exerciseId;
  final bool isFavorite;
  final int? favoriteGroup;     // 1–5 (null si no es favorito)
  final String? favoriteColor;  // 'red'/'orange'/'yellow'/'green'/'blue'
  final bool isHidden;
  final String notes;
  final String? customVideoUrl;
  final DateTime? updatedAt;
  final String timestamp;

  const ExercisePref({
    required this.exerciseId,
    this.isFavorite = false,
    this.favoriteGroup,
    this.favoriteColor,
    this.isHidden = false,
    this.notes = '',
    this.customVideoUrl,
    this.updatedAt,
    required this.timestamp,
  });

  static ExercisePref empty(String exerciseId) => ExercisePref(
        exerciseId: exerciseId,
        timestamp: DateTime.now().toIso8601String(),
      );

  ExercisePref copyWith({
    String? exerciseId,
    bool? isFavorite,
    int? favoriteGroup,
    String? favoriteColor,
    bool? isHidden,
    String? notes,
    String? customVideoUrl,
    DateTime? updatedAt,
    String? timestamp,
    bool clearFavoriteGroup = false,
    bool clearFavoriteColor = false,
    bool clearCustomVideoUrl = false,
  }) {
    return ExercisePref(
      exerciseId: exerciseId ?? this.exerciseId,
      isFavorite: isFavorite ?? this.isFavorite,
      favoriteGroup: clearFavoriteGroup ? null : favoriteGroup ?? this.favoriteGroup,
      favoriteColor: clearFavoriteColor ? null : favoriteColor ?? this.favoriteColor,
      isHidden: isHidden ?? this.isHidden,
      notes: notes ?? this.notes,
      customVideoUrl: clearCustomVideoUrl ? null : customVideoUrl ?? this.customVideoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory ExercisePref.fromMap(Map<String, dynamic> map) {
    return ExercisePref(
      exerciseId: map['exerciseId'] as String,
      isFavorite: map['isFavorite'] as bool? ?? false,
      favoriteGroup: map['favoriteGroup'] as int?,
      favoriteColor: map['favoriteColor'] as String?,
      isHidden: map['isHidden'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      customVideoUrl: map['customVideoUrl'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'isFavorite': isFavorite,
      'favoriteGroup': favoriteGroup,
      'favoriteColor': favoriteColor,
      'isHidden': isHidden,
      'notes': notes,
      'customVideoUrl': customVideoUrl,
      'updatedAt': updatedAt?.toIso8601String(),
      'timestamp': timestamp,
    };
  }

  /// Color de favorito como objeto Flutter Color (hex value)
  static const Map<String, int> favoriteColorValues = {
    'red':    0xFFE53935,
    'orange': 0xFFFF6F00,
    'yellow': 0xFFFFD600,
    'green':  0xFF43A047,
    'blue':   0xFF1E88E5,
  };

  static const Map<int, String> groupColorNames = {
    1: 'red',
    2: 'orange',
    3: 'yellow',
    4: 'green',
    5: 'blue',
  };

  int? get favoriteColorValue {
    if (favoriteColor == null) return null;
    return favoriteColorValues[favoriteColor];
  }
}
