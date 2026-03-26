import 'package:equatable/equatable.dart';
import 'exercise_model.dart';

enum WorkoutStatus { inProgress, completed }

class WorkoutModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final List<ExerciseModel> exercises;
  final WorkoutStatus status;
  final Duration? duration;
  final String? notes;
  final String? aiInsights;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.exercises,
    this.status = WorkoutStatus.inProgress,
    this.duration,
    this.notes,
    this.aiInsights,
  });

  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    List<ExerciseModel>? exercises,
    WorkoutStatus? status,
    Duration? duration,
    String? notes,
    String? aiInsights,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      aiInsights: aiInsights ?? this.aiInsights,
    );
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => ExerciseModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: WorkoutStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => WorkoutStatus.inProgress,
      ),
      duration: map['durationSeconds'] != null
          ? Duration(seconds: map['durationSeconds'] as int)
          : null,
      notes: map['notes'] as String?,
      aiInsights: map['aiInsights'] as String?,
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
    };
  }

  // Total tonelaje del entrenamiento
  int get totalVolume =>
      exercises.fold(0, (sum, e) => sum + e.totalVolume);

  // Mejor 1RM estimado de los tres levantamientos principales
  double get totalEstimated1RM {
    double squat = 0, bench = 0, deadlift = 0;
    for (final exercise in exercises) {
      if (exercise.category == ExerciseCategory.squat) {
        squat = exercise.bestEstimated1RM > squat ? exercise.bestEstimated1RM : squat;
      } else if (exercise.category == ExerciseCategory.bench) {
        bench = exercise.bestEstimated1RM > bench ? exercise.bestEstimated1RM : bench;
      } else if (exercise.category == ExerciseCategory.deadlift) {
        deadlift = exercise.bestEstimated1RM > deadlift ? exercise.bestEstimated1RM : deadlift;
      }
    }
    return squat + bench + deadlift;
  }

  @override
  List<Object?> get props =>
      [id, userId, title, date, exercises, status, duration, notes, aiInsights];
}
