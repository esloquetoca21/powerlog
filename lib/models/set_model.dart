// Colección Firestore: 'sets' (subcolección de 'sessions')
class SetModel {
  final String id;
  final int setNumber;
  final double weight;    // kg
  final int reps;
  final double? rpe;      // 1–10, paso 0.5
  final String? notes;
  final bool completed;
  final DateTime timestamp;

  const SetModel({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.rpe,
    this.notes,
    this.completed = false,
    required this.timestamp,
  });

  SetModel copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    String? notes,
    bool? completed,
    DateTime? timestamp,
  }) {
    return SetModel(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SetModel.fromMap(Map<String, dynamic> map) {
    return SetModel(
      id: map['id'] as String,
      setNumber: map['setNumber'] as int,
      weight: (map['weight'] as num).toDouble(),
      reps: map['reps'] as int,
      rpe: map['rpe'] != null ? (map['rpe'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      completed: map['completed'] as bool? ?? false,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'notes': notes,
      'completed': completed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 1RM estimado con la fórmula de Epley: weight × (1 + reps/30)
  double get estimated1RM {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// 1RM estimado con la fórmula de Brzycki: weight / (1.0278 - 0.0278 × reps)
  double get estimated1RMBrzycki {
    if (reps == 1) return weight;
    return weight / (1.0278 - 0.0278 * reps);
  }
}
