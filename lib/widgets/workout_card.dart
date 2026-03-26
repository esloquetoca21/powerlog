import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout_model.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;

  const WorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM', 'es').format(workout.date);
    final duration = workout.duration != null
        ? '${workout.duration!.inMinutes} min'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workout.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (duration != null)
                Text(duration,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateStr,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13)),
          if (workout.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: workout.exercises
                  .map((e) => _ExerciseChip(name: e.name))
                  .toList(),
            ),
          ],
          if (workout.totalVolume > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                    icon: Icons.bar_chart,
                    label: '${workout.totalVolume} kg vol.'),
                const SizedBox(width: 8),
                if (workout.totalEstimated1RM > 0)
                  _StatChip(
                    icon: Icons.emoji_events_outlined,
                    label:
                        'Total: ${workout.totalEstimated1RM.toStringAsFixed(0)} kg',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String name;
  const _ExerciseChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(name,
          style: const TextStyle(color: Color(0xFFE53935), fontSize: 12)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ],
    );
  }
}
