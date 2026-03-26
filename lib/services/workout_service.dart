import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/workout_model.dart';
import '../models/exercise_model.dart';

class WorkoutService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<WorkoutModel> _workouts = [];
  WorkoutModel? _activeWorkout;
  bool _isLoading = false;

  List<WorkoutModel> get workouts => _workouts;
  WorkoutModel? get activeWorkout => _activeWorkout;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkout => _activeWorkout != null;

  Future<void> loadWorkouts(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      _workouts = snapshot.docs
          .map((doc) => WorkoutModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading workouts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  WorkoutModel startWorkout({required String userId, required String title}) {
    final workout = WorkoutModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      date: DateTime.now(),
      exercises: [],
      status: WorkoutStatus.inProgress,
    );
    _activeWorkout = workout;
    notifyListeners();
    return workout;
  }

  void addExercise(ExerciseModel exercise) {
    if (_activeWorkout == null) return;
    final updated = _activeWorkout!.copyWith(
      exercises: [..._activeWorkout!.exercises, exercise],
    );
    _activeWorkout = updated;
    notifyListeners();
  }

  void updateExercise(ExerciseModel exercise) {
    if (_activeWorkout == null) return;
    final exercises = _activeWorkout!.exercises.map((e) {
      return e.id == exercise.id ? exercise : e;
    }).toList();
    _activeWorkout = _activeWorkout!.copyWith(exercises: exercises);
    notifyListeners();
  }

  void removeExercise(String exerciseId) {
    if (_activeWorkout == null) return;
    final exercises =
        _activeWorkout!.exercises.where((e) => e.id != exerciseId).toList();
    _activeWorkout = _activeWorkout!.copyWith(exercises: exercises);
    notifyListeners();
  }

  Future<WorkoutModel> finishWorkout({
    required Duration duration,
    String? notes,
    String? aiInsights,
  }) async {
    if (_activeWorkout == null) throw Exception('No hay entrenamiento activo');

    final completed = _activeWorkout!.copyWith(
      status: WorkoutStatus.completed,
      duration: duration,
      notes: notes,
      aiInsights: aiInsights,
    );

    await _db
        .collection('workouts')
        .doc(completed.id)
        .set(completed.toMap());

    _workouts = [completed, ..._workouts];
    _activeWorkout = null;
    notifyListeners();
    return completed;
  }

  void cancelWorkout() {
    _activeWorkout = null;
    notifyListeners();
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _db.collection('workouts').doc(workoutId).delete();
    _workouts = _workouts.where((w) => w.id != workoutId).toList();
    notifyListeners();
  }

  // Estadísticas de progreso por ejercicio
  List<WorkoutModel> getWorkoutsWithExercise(String exerciseName) {
    return _workouts
        .where((w) => w.exercises.any((e) =>
            e.name.toLowerCase().contains(exerciseName.toLowerCase())))
        .toList();
  }

  // Obtener mejor marca histórica de un ejercicio
  double getBestEstimated1RM(String exerciseName) {
    double best = 0;
    for (final workout in _workouts) {
      for (final exercise in workout.exercises) {
        if (exercise.name.toLowerCase().contains(exerciseName.toLowerCase())) {
          if (exercise.bestEstimated1RM > best) {
            best = exercise.bestEstimated1RM;
          }
        }
      }
    }
    return best;
  }
}
