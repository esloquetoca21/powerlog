import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout_model.dart';
import '../../models/exercise_model.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutModel workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, d MMMM yyyy', 'es').format(workout.date);

    return Scaffold(
      appBar: AppBar(title: Text(workout.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Date & duration row
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Text(dateStr,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 14)),
              if (workout.duration != null) ...[
                const Spacer(),
                const Icon(Icons.timer_outlined,
                    color: Colors.white38, size: 16),
                const SizedBox(width: 4),
                Text('${workout.duration!.inMinutes} min',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 14)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // Stats cards
          Row(
            children: [
              _StatCard(
                label: 'Volumen total',
                value: '${workout.totalVolume} kg',
                icon: Icons.bar_chart,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Total SBD',
                value:
                    '${workout.totalEstimated1RM.toStringAsFixed(0)} kg',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // AI Insights
          if (workout.aiInsights != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE53935).withOpacity(0.15),
                    const Color(0xFF1A1A1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome,
                          color: Color(0xFFE53935), size: 16),
                      SizedBox(width: 8),
                      Text('Análisis IA',
                          style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(workout.aiInsights!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Exercises
          const Text(
            'Ejercicios',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...workout.exercises.map((e) => _ExerciseDetail(exercise: e)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFE53935), size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDetail extends StatelessWidget {
  final ExerciseModel exercise;

  const _ExerciseDetail({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exercise.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
              Text(
                '1RM: ${exercise.bestEstimated1RM.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    color: Color(0xFFE53935), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...exercise.sets.map(
            (set) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text('Serie ${set.setNumber}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13)),
                  ),
                  Text(
                    '${set.weight} kg × ${set.reps}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                  ),
                  if (set.rpe != null)
                    Text(' @ RPE ${set.rpe}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13)),
                  const Spacer(),
                  if (set.completed)
                    const Icon(Icons.check_circle,
                        color: Color(0xFFE53935), size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
