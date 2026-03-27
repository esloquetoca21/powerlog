// Colección Firestore: 'sessions'
import 'exercise_model.dart';

enum SessionStatus { inProgress, completed }

class SessionModel {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final List<ExerciseModel> exercises;
  final SessionStatus status;
  final Duration? duration;
  final String? notes;
  final String? aiInsights; // análisis post-sesión generado por IA
  // Valoraciones de bienestar (1–10)
  final int? ratingMood;      // sensación del entrenamiento
  final int? ratingFatigue;   // fatiga percibida
  final int? ratingCalories;  // ingesta calórica últimas 24 h
  final int? ratingSleep;     // calidad del sueño
  final int? ratingStress;    // estrés últimas 24 h
  final DateTime timestamp;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.exercises,
    this.status = SessionStatus.inProgress,
    this.duration,
    this.notes,
    this.aiInsights,
    this.ratingMood,
    this.ratingFatigue,
    this.ratingCalories,
    this.ratingSleep,
    this.ratingStress,
    required this.timestamp,
  });

  SessionModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    List<ExerciseModel>? exercises,
    SessionStatus? status,
    Duration? duration,
    String? notes,
    String? aiInsights,
    int? ratingMood,
    int? ratingFatigue,
    int? ratingCalories,
    int? ratingSleep,
    int? ratingStress,
    DateTime? timestamp,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      aiInsights: aiInsights ?? this.aiInsights,
      ratingMood: ratingMood ?? this.ratingMood,
      ratingFatigue: ratingFatigue ?? this.ratingFatigue,
      ratingCalories: ratingCalories ?? this.ratingCalories,
      ratingSleep: ratingSleep ?? this.ratingSleep,
      ratingStress: ratingStress ?? this.ratingStress,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => ExerciseModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SessionStatus.inProgress,
      ),
      duration: map['durationSeconds'] != null
          ? Duration(seconds: map['durationSeconds'] as int)
          : null,
      notes: map['notes'] as String?,
      aiInsights: map['aiInsights'] as String?,
      ratingMood: map['ratingMood'] as int?,
      ratingFatigue: map['ratingFatigue'] as int?,
      ratingCalories: map['ratingCalories'] as int?,
      ratingSleep: map['ratingSleep'] as int?,
      ratingStress: map['ratingStress'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'status': status.name,
      'durationSeconds': duration?.inSeconds,
      'notes': notes,
      'aiInsights': aiInsights,
      'ratingMood': ratingMood,
      'ratingFatigue': ratingFatigue,
      'ratingCalories': ratingCalories,
      'ratingSleep': ratingSleep,
      'ratingStress': ratingStress,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Tonelaje total de la sesión (kg × reps de todos los ejercicios)
  int get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  /// RPE medio de la sesión
  double? get averageRpe {
    final rpes = exercises
        .map((e) => e.averageRpe)
        .whereType<double>()
        .toList();
    if (rpes.isEmpty) return null;
    return rpes.fold(0.0, (a, b) => a + b) / rpes.length;
  }

  /// Mejor 1RM estimado por cada levantamiento principal (SBD)
  _SBDTotal get sbdTotal {
    double squat = 0, bench = 0, deadlift = 0;
    for (final ex in exercises) {
      final rm = ex.bestEstimated1RM;
      if (ex.category == ExerciseCategory.squat && rm > squat) squat = rm;
      if (ex.category == ExerciseCategory.bench && rm > bench) bench = rm;
      if (ex.category == ExerciseCategory.deadlift && rm > deadlift) deadlift = rm;
    }
    return _SBDTotal(squat: squat, bench: bench, deadlift: deadlift);
  }
}

class _SBDTotal {
  final double squat;
  final double bench;
  final double deadlift;

  const _SBDTotal({
    required this.squat,
    required this.bench,
    required this.deadlift,
  });

  double get total => squat + bench + deadlift;
}
