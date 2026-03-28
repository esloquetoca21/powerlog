// Colección Firestore: 'sets' (subcolección de 'sessions')

enum SetType { normal, failure, dropSet, restPause }

/// Sub-serie para drop sets y rest-pause (solo peso y reps).
class SubSet {
  final double weight;
  final int reps;

  const SubSet({required this.weight, required this.reps});

  SubSet copyWith({double? weight, int? reps}) =>
      SubSet(weight: weight ?? this.weight, reps: reps ?? this.reps);

  factory SubSet.fromMap(Map<String, dynamic> m) => SubSet(
        weight: (m['weight'] as num).toDouble(),
        reps: m['reps'] as int,
      );

  Map<String, dynamic> toMap() => {'weight': weight, 'reps': reps};
}

class SetModel {
  final String id;
  final int setNumber;
  final double weight;    // kg
  final int reps;
  final double? rpe;      // 1–10, paso 0.5
  final int? rir;         // Reps In Reserve 0–5
  final String? notes;
  final SetType setType;
  final List<SubSet>? subSets; // drops o pausa rest-pause
  final bool completed;
  final DateTime timestamp;

  const SetModel({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.rpe,
    this.rir,
    this.notes,
    this.setType = SetType.normal,
    this.subSets,
    this.completed = false,
    required this.timestamp,
  });

  SetModel copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    int? rir,
    String? notes,
    SetType? setType,
    List<SubSet>? subSets,
    bool? completed,
    DateTime? timestamp,
    bool clearRpe = false,
    bool clearRir = false,
    bool clearNotes = false,
    bool clearSubSets = false,
  }) {
    return SetModel(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: clearRpe ? null : (rpe ?? this.rpe),
      rir: clearRir ? null : (rir ?? this.rir),
      notes: clearNotes ? null : (notes ?? this.notes),
      setType: setType ?? this.setType,
      subSets: clearSubSets ? null : (subSets ?? this.subSets),
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
      rir: map['rir'] as int?,
      notes: map['notes'] as String?,
      setType: SetType.values.firstWhere(
        (t) => t.name == map['setType'],
        orElse: () => SetType.normal,
      ),
      subSets: map['subSets'] != null
          ? (map['subSets'] as List<dynamic>)
              .map((s) => SubSet.fromMap(s as Map<String, dynamic>))
              .toList()
          : null,
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
      'rir': rir,
      'notes': notes,
      'setType': setType.name,
      'subSets': subSets?.map((s) => s.toMap()).toList(),
      'completed': completed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  double get estimated1RM {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  double get estimated1RMBrzycki {
    if (reps == 1) return weight;
    return weight / (1.0278 - 0.0278 * reps);
  }
}
