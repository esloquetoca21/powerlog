import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/session_model.dart';
import '../models/exercise_model.dart';

// Colecciones Firestore: 'sessions', 'sets' (según PRD sección 7)
class SessionService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<SessionModel> _sessions = [];
  SessionModel? _activeSession;
  bool _isLoading = false;

  List<SessionModel> get sessions => _sessions;
  SessionModel? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _activeSession != null;

  Future<void> loadSessions(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .limit(50)
          .get();

      _sessions = snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  SessionModel startSession({required String userId, required String title}) {
    final now = DateTime.now();
    final session = SessionModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      date: now,
      exercises: [],
      status: SessionStatus.inProgress,
      timestamp: now,
    );
    _activeSession = session;
    notifyListeners();
    return session;
  }

  void addExercise(ExerciseModel exercise) {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(
      exercises: [..._activeSession!.exercises, exercise],
    );
    notifyListeners();
  }

  void updateExercise(ExerciseModel exercise) {
    if (_activeSession == null) return;
    final exercises = _activeSession!.exercises
        .map((e) => e.id == exercise.id ? exercise : e)
        .toList();
    _activeSession = _activeSession!.copyWith(exercises: exercises);
    notifyListeners();
  }

  void removeExercise(String exerciseId) {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(
      exercises: _activeSession!.exercises.where((e) => e.id != exerciseId).toList(),
    );
    notifyListeners();
  }

  Future<SessionModel> finishSession({
    required Duration duration,
    String? notes,
    String? aiInsights,
  }) async {
    if (_activeSession == null) throw Exception('No hay sesión activa');

    final completed = _activeSession!.copyWith(
      status: SessionStatus.completed,
      duration: duration,
      notes: notes,
      aiInsights: aiInsights,
    );

    await _db.collection('sessions').doc(completed.id).set(completed.toMap());

    _sessions = [completed, ..._sessions];
    _activeSession = null;
    notifyListeners();
    return completed;
  }

  void cancelSession() {
    _activeSession = null;
    notifyListeners();
  }

  Future<void> updateSession(SessionModel updated) async {
    await _db.collection('sessions').doc(updated.id).set(updated.toMap());
    _sessions = _sessions
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).delete();
    _sessions = _sessions.where((s) => s.id != sessionId).toList();
    notifyListeners();
  }

  double getBestEstimated1RM(String exerciseName) {
    double best = 0;
    for (final session in _sessions) {
      for (final exercise in session.exercises) {
        if (exercise.name.toLowerCase().contains(exerciseName.toLowerCase())) {
          if (exercise.bestEstimated1RM > best) best = exercise.bestEstimated1RM;
        }
      }
    }
    return best;
  }
}
