import '../models/session_model.dart';
import '../models/set_model.dart';

// ── ExerciseStats data class ───────────────────────────────────────────────

class ExerciseStats {
  final String exerciseName;

  /// Completed set with the highest weight.
  final SetModel? personalRecord;

  /// Maximum Epley-estimated 1RM across all historical completed sets.
  final double maxEstimated1RM;

  /// Date of the session that produced [personalRecord].
  final DateTime? prDate;

  final int totalSets;

  /// Sum of (weight × reps) across all completed sets.
  final int totalVolume;

  /// Date the exercise was last performed.
  final DateTime? lastPerformed;

  /// Maps rep count → max weight found in history for that exact rep count.
  /// Keys are drawn from [1, 2, 3, 5, 8, 10, 12, 15, 20].
  final Map<int, double> strengthCurve;

  /// One entry per session where the exercise was performed: date + max Epley
  /// 1RM of that session. Ordered chronologically.
  final List<({DateTime date, double value})> estimated1rmHistory;

  /// Session that produced the most volume for this exercise.
  final SessionModel? bestVolumeSession;

  /// Scatter-chart data: load percentage of current 1RM vs. RPE.
  final List<({double loadPct, double rpe})> rpeVsLoad;

  /// All completed sets, sorted chronologically by session date.
  final List<SetModel> allSets;

  const ExerciseStats({
    required this.exerciseName,
    this.personalRecord,
    this.maxEstimated1RM = 0,
    this.prDate,
    this.totalSets = 0,
    this.totalVolume = 0,
    this.lastPerformed,
    this.strengthCurve = const {},
    this.estimated1rmHistory = const [],
    this.bestVolumeSession,
    this.rpeVsLoad = const [],
    this.allSets = const [],
  });
}

// ── Service ────────────────────────────────────────────────────────────────

class ExerciseStatsService {
  // Epley: weight × (1 + reps/30). For 1 rep → return weight directly.
  static double _epley(double weight, int reps) {
    if (reps <= 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// Returns an [ExerciseStats] with all zeros/nulls/empty collections.
  ExerciseStats empty(String exerciseName) => ExerciseStats(
        exerciseName: exerciseName,
        strengthCurve: const {},
        estimated1rmHistory: const [],
        rpeVsLoad: const [],
        allSets: const [],
      );

  /// Calculates full stats for [exerciseName] from the provided [sessions].
  ///
  /// [current1rm] is used to compute load percentage in [rpeVsLoad].
  ExerciseStats calculate(
    String exerciseName,
    List<SessionModel> sessions,
    double current1rm,
  ) {
    final nameLower = exerciseName.toLowerCase();

    // ── 1. Collect all (session, set) pairs for this exercise ───────────────
    final List<({SessionModel session, SetModel set})> pairs = [];

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.name.toLowerCase() != nameLower) continue;
        for (final set in exercise.sets) {
          if (!set.completed) continue;
          pairs.add((session: session, set: set));
        }
      }
    }

    if (pairs.isEmpty) return empty(exerciseName);

    // Sort pairs chronologically by session date.
    pairs.sort((a, b) => a.session.date.compareTo(b.session.date));

    final allSets = pairs.map((p) => p.set).toList();

    // ── 2. PR (max weight among completed sets) ────────────────────────────
    SetModel? pr;
    DateTime? prDate;
    for (final p in pairs) {
      if (pr == null || p.set.weight > pr.weight) {
        pr = p.set;
        prDate = p.session.date;
      }
    }

    // ── 3. Max estimated 1RM ───────────────────────────────────────────────
    double maxE1rm = 0;
    for (final p in pairs) {
      final e = _epley(p.set.weight, p.set.reps);
      if (e > maxE1rm) maxE1rm = e;
    }

    // ── 4. Totals ──────────────────────────────────────────────────────────
    final totalSets = allSets.length;
    int totalVolume = 0;
    for (final s in allSets) {
      totalVolume += (s.weight * s.reps).round();
    }

    // ── 5. Last performed ─────────────────────────────────────────────────
    // pairs is sorted chronologically → last entry has the most recent date.
    final lastPerformed = pairs.last.session.date;

    // ── 6. Strength curve ─────────────────────────────────────────────────
    const repCounts = [1, 2, 3, 5, 8, 10, 12, 15, 20];
    final strengthCurve = <int, double>{};
    for (final rep in repCounts) {
      double maxWeight = 0;
      for (final s in allSets) {
        if (s.reps == rep && s.weight > maxWeight) {
          maxWeight = s.weight;
        }
      }
      if (maxWeight > 0) strengthCurve[rep] = maxWeight;
    }

    // ── 7. Estimated 1RM history (one point per session) ──────────────────
    // Group pairs by session id, preserving chronological order of sessions.
    final sessionOrder = <String>[];
    final sessionMap = <String, ({DateTime date, List<SetModel> sets})>{};

    for (final p in pairs) {
      final sid = p.session.id;
      if (!sessionMap.containsKey(sid)) {
        sessionOrder.add(sid);
        sessionMap[sid] = (date: p.session.date, sets: []);
      }
      sessionMap[sid]!.sets.add(p.set);
    }

    final estimated1rmHistory = <({DateTime date, double value})>[];
    for (final sid in sessionOrder) {
      final entry = sessionMap[sid]!;
      double maxSessionE1rm = 0;
      for (final s in entry.sets) {
        final e = _epley(s.weight, s.reps);
        if (e > maxSessionE1rm) maxSessionE1rm = e;
      }
      estimated1rmHistory.add((date: entry.date, value: maxSessionE1rm));
    }

    // ── 8. Best volume session ─────────────────────────────────────────────
    final sessionVolume = <String, int>{};
    final sessionRef = <String, SessionModel>{};

    for (final p in pairs) {
      final sid = p.session.id;
      sessionRef[sid] ??= p.session;
      sessionVolume[sid] =
          (sessionVolume[sid] ?? 0) + (p.set.weight * p.set.reps).round();
    }

    SessionModel? bestVolumeSession;
    int maxVolume = 0;
    sessionVolume.forEach((sid, vol) {
      if (vol > maxVolume) {
        maxVolume = vol;
        bestVolumeSession = sessionRef[sid];
      }
    });

    // ── 9. RPE vs load scatter ─────────────────────────────────────────────
    final rpeVsLoad = <({double loadPct, double rpe})>[];
    if (current1rm > 0) {
      for (final s in allSets) {
        if (s.rpe != null) {
          rpeVsLoad.add((
            loadPct: (s.weight / current1rm) * 100,
            rpe: s.rpe!,
          ));
        }
      }
    }

    return ExerciseStats(
      exerciseName: exerciseName,
      personalRecord: pr,
      maxEstimated1RM: maxE1rm,
      prDate: prDate,
      totalSets: totalSets,
      totalVolume: totalVolume,
      lastPerformed: lastPerformed,
      strengthCurve: strengthCurve,
      estimated1rmHistory: estimated1rmHistory,
      bestVolumeSession: bestVolumeSession,
      rpeVsLoad: rpeVsLoad,
      allSets: allSets,
    );
  }
}
