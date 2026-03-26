import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_model.dart';
import '../models/set_model.dart';
import '../services/session_service.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  static const _uuid = Uuid();

  const ExerciseCard({super.key, required this.exercise});

  void _addSet(BuildContext context) {
    final lastSet = exercise.sets.isEmpty
        ? SetModel(id: _uuid.v4(), setNumber: 1, weight: 0, reps: 5, timestamp: DateTime.now())
        : exercise.sets.last;

    final newSet = SetModel(
      id: _uuid.v4(),
      setNumber: exercise.sets.length + 1,
      weight: lastSet.weight,
      reps: lastSet.reps,
      timestamp: DateTime.now(),
    );
    final updated = exercise.copyWith(sets: [...exercise.sets, newSet]);
    context.read<SessionService>().updateExercise(updated);
  }

  void _updateSet(BuildContext context, SetModel set,
      {double? weight, int? reps}) {
    final updatedSet = set.copyWith(weight: weight, reps: reps);
    final sets =
        exercise.sets.map((s) => s.setNumber == set.setNumber ? updatedSet : s).toList();
    context.read<SessionService>().updateExercise(exercise.copyWith(sets: sets));
  }

  void _toggleSetCompleted(BuildContext context, SetModel set) {
    final updatedSet = set.copyWith(completed: !set.completed);
    final sets = exercise.sets
        .map((s) => s.setNumber == set.setNumber ? updatedSet : s)
        .toList();
    context.read<SessionService>().updateExercise(exercise.copyWith(sets: sets));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _categoryColor(exercise.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.white.withOpacity(0.3), size: 20),
                  onPressed: () => context
                      .read<SessionService>()
                      .removeExercise(exercise.id),
                ),
              ],
            ),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 28),
                _header('Serie', flex: 1),
                _header('Peso (kg)', flex: 2),
                _header('Reps', flex: 2),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Sets
          ...exercise.sets.map(
            (set) => _SetRow(
              set: set,
              onWeightChanged: (w) => _updateSet(context, set, weight: w),
              onRepsChanged: (r) => _updateSet(context, set, reps: r),
              onToggleCompleted: () => _toggleSetCompleted(context, set),
            ),
          ),
          // Add set button
          TextButton.icon(
            onPressed: () => _addSet(context),
            icon: const Icon(Icons.add, color: Color(0xFFE53935), size: 18),
            label: const Text('Añadir serie',
                style: TextStyle(color: Color(0xFFE53935), fontSize: 14)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _header(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }

  Color _categoryColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.squat:
        return Colors.blueAccent;
      case ExerciseCategory.bench:
        return Colors.greenAccent;
      case ExerciseCategory.deadlift:
        return const Color(0xFFE53935);
      case ExerciseCategory.accessory:
        return Colors.orangeAccent;
    }
  }
}

class _SetRow extends StatefulWidget {
  final SetModel set;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onToggleCompleted;

  const _SetRow({
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleCompleted,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.set.weight > 0 ? widget.set.weight.toString() : '');
    _repsCtrl = TextEditingController(
        text: widget.set.reps > 0 ? widget.set.reps.toString() : '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.set.completed
          ? const Color(0xFFE53935).withOpacity(0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${widget.set.setNumber}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: _InlineInput(
              controller: _weightCtrl,
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) widget.onWeightChanged(d);
              },
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _InlineInput(
              controller: _repsCtrl,
              onChanged: (v) {
                final i = int.tryParse(v);
                if (i != null) widget.onRepsChanged(i);
              },
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onToggleCompleted,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.set.completed
                    ? const Color(0xFFE53935)
                    : Colors.transparent,
                border: Border.all(
                  color: widget.set.completed
                      ? const Color(0xFFE53935)
                      : Colors.white24,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.set.completed
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  const _InlineInput({
    required this.controller,
    required this.onChanged,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
