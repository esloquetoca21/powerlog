import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_model.dart';
import '../models/set_model.dart';
import '../services/session_service.dart';

class ExerciseCard extends StatefulWidget {
  final ExerciseModel exercise;
  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  static const _uuid = Uuid();

  // RPE o RIR a nivel de tarjeta (el usuario elige cuál prefiere)
  bool _useRir = false;
  // Mostrar campo de notas del ejercicio
  bool _showExerciseNotes = false;
  // Qué series tienen las notas expandidas
  final Map<String, bool> _setNoteExpanded = {};

  late TextEditingController _exerciseNotesCtrl;

  @override
  void initState() {
    super.initState();
    _exerciseNotesCtrl =
        TextEditingController(text: widget.exercise.notes ?? '');
    _showExerciseNotes =
        widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty;
  }

  @override
  void didUpdateWidget(ExerciseCard old) {
    super.didUpdateWidget(old);
    // Sincroniza el campo si el modelo cambió externamente
    if (old.exercise.notes != widget.exercise.notes &&
        !_exerciseNotesCtrl.text.isNotEmpty) {
      _exerciseNotesCtrl.text = widget.exercise.notes ?? '';
    }
  }

  @override
  void dispose() {
    _exerciseNotesCtrl.dispose();
    super.dispose();
  }

  // ── Helpers de escritura ──────────────────────────────────────────────────

  void _persistExercise(ExerciseModel updated) =>
      context.read<SessionService>().updateExercise(updated);

  void _saveExerciseNotes(String value) {
    _persistExercise(widget.exercise.copyWith(
      notes: value.trim().isEmpty ? null : value.trim(),
    ));
  }

  void _updateSet(SetModel updated) {
    final sets = widget.exercise.sets
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    _persistExercise(widget.exercise.copyWith(sets: sets));
  }

  void _removeSet(String setId) {
    var sets =
        widget.exercise.sets.where((s) => s.id != setId).toList();
    sets = sets
        .asMap()
        .entries
        .map((e) => e.value.copyWith(setNumber: e.key + 1))
        .toList();
    _persistExercise(widget.exercise.copyWith(sets: sets));
  }

  void _addSet() {
    final last = widget.exercise.sets.isEmpty
        ? SetModel(
            id: _uuid.v4(),
            setNumber: 1,
            weight: 0,
            reps: 5,
            timestamp: DateTime.now())
        : widget.exercise.sets.last;

    final newSet = SetModel(
      id: _uuid.v4(),
      setNumber: widget.exercise.sets.length + 1,
      weight: last.weight,
      reps: last.reps,
      rpe: last.rpe,
      rir: last.rir,
      timestamp: DateTime.now(),
    );
    _persistExercise(
        widget.exercise.copyWith(sets: [...widget.exercise.sets, newSet]));
  }

  void _cycleSetType(SetModel set) {
    final next =
        SetType.values[(set.setType.index + 1) % SetType.values.length];
    _updateSet(set.copyWith(setType: next));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _categoryColor(ex.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                // Toggle RPE / RIR
                GestureDetector(
                  onTap: () => setState(() => _useRir = !_useRir),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _useRir ? 'RIR' : 'RPE',
                      style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Notas del ejercicio
                IconButton(
                  icon: Icon(
                    Icons.notes_outlined,
                    color: _showExerciseNotes
                        ? const Color(0xFFE53935)
                        : Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showExerciseNotes = !_showExerciseNotes),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Notas del ejercicio',
                ),
                // Eliminar ejercicio
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.white.withOpacity(0.3), size: 20),
                  onPressed: () =>
                      context.read<SessionService>().removeExercise(ex.id),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // ── Notas del ejercicio ──────────────────────────────────────────
          if (_showExerciseNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _exerciseNotesCtrl,
                onChanged: _saveExerciseNotes,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Notas del ejercicio (técnica, sensaciones...)',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFE53935), width: 1),
                  ),
                ),
              ),
            ),

          // ── Cabecera de columnas ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Row(
              children: [
                const SizedBox(width: 26), // tipo de serie
                const SizedBox(width: 26), // número de serie
                _colHeader('Peso', flex: 2),
                const SizedBox(width: 6),
                _colHeader('Reps', flex: 2),
                const SizedBox(width: 6),
                _colHeader(_useRir ? 'RIR' : 'RPE', flex: 1),
                const SizedBox(width: 6),
                const SizedBox(width: 32), // checkbox
                const SizedBox(width: 28), // nota serie
              ],
            ),
          ),

          // ── Series ───────────────────────────────────────────────────────
          ...ex.sets.map((set) {
            final noteOpen = _setNoteExpanded[set.id] ?? false;
            return _SetBlock(
              set: set,
              useRir: _useRir,
              noteOpen: noteOpen,
              onUpdate: _updateSet,
              onRemove: () => _removeSet(set.id),
              onCycleType: () => _cycleSetType(set),
              onToggleNote: () =>
                  setState(() => _setNoteExpanded[set.id] = !noteOpen),
            );
          }),

          // ── Añadir serie ─────────────────────────────────────────────────
          TextButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add,
                color: Color(0xFFE53935), size: 18),
            label: const Text('Añadir serie',
                style: TextStyle(
                    color: Color(0xFFE53935), fontSize: 14)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _colHeader(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      );

  Color _categoryColor(ExerciseCategory cat) => switch (cat) {
        ExerciseCategory.squat => Colors.blueAccent,
        ExerciseCategory.bench => Colors.greenAccent,
        ExerciseCategory.deadlift => const Color(0xFFE53935),
        ExerciseCategory.accessory => Colors.orangeAccent,
      };
}

// ── Bloque de serie (fila + nota opcional) ────────────────────────────────────

class _SetBlock extends StatefulWidget {
  final SetModel set;
  final bool useRir;
  final bool noteOpen;
  final ValueChanged<SetModel> onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onCycleType;
  final VoidCallback onToggleNote;

  const _SetBlock({
    required this.set,
    required this.useRir,
    required this.noteOpen,
    required this.onUpdate,
    required this.onRemove,
    required this.onCycleType,
    required this.onToggleNote,
  });

  @override
  State<_SetBlock> createState() => _SetBlockState();
}

class _SetBlockState extends State<_SetBlock> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _effortCtrl; // RPE o RIR
  late TextEditingController _setNotesCtrl;

  @override
  void initState() {
    super.initState();
    final w = widget.set.weight;
    _weightCtrl = TextEditingController(
        text: w == 0 ? '' : (w == w.truncateToDouble() ? w.toInt().toString() : w.toString()));
    _repsCtrl = TextEditingController(
        text: widget.set.reps == 0 ? '' : widget.set.reps.toString());
    _effortCtrl = TextEditingController(text: _effortText());
    _setNotesCtrl =
        TextEditingController(text: widget.set.notes ?? '');
  }

  @override
  void didUpdateWidget(_SetBlock old) {
    super.didUpdateWidget(old);
    if (old.useRir != widget.useRir) {
      _effortCtrl.text = _effortText();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _effortCtrl.dispose();
    _setNotesCtrl.dispose();
    super.dispose();
  }

  String _effortText() {
    if (widget.useRir) {
      return widget.set.rir?.toString() ?? '';
    }
    final rpe = widget.set.rpe;
    if (rpe == null) return '';
    return rpe == rpe.truncateToDouble() ? rpe.toInt().toString() : rpe.toString();
  }

  void _notifyWeight(String v) {
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d != null) widget.onUpdate(widget.set.copyWith(weight: d));
  }

  void _notifyReps(String v) {
    final i = int.tryParse(v);
    if (i != null) widget.onUpdate(widget.set.copyWith(reps: i));
  }

  void _notifyEffort(String v) {
    if (widget.useRir) {
      final i = int.tryParse(v);
      widget.onUpdate(widget.set.copyWith(
          rir: i, clearRpe: true));
    } else {
      final d = double.tryParse(v.replaceAll(',', '.'));
      widget.onUpdate(widget.set.copyWith(
          rpe: d, clearRir: true));
    }
  }

  void _saveSetNote(String v) {
    widget.onUpdate(widget.set.copyWith(
        notes: v.trim().isEmpty ? null : v.trim()));
  }

  // Color por tipo de serie
  Color _typeColor(SetType t) => switch (t) {
        SetType.normal => Colors.transparent,
        SetType.failure => const Color(0xFFE53935),
        SetType.dropSet => Colors.orangeAccent,
        SetType.restPause => Colors.purpleAccent,
      };

  String _typeLabel(SetType t) => switch (t) {
        SetType.normal => '●',
        SetType.failure => 'F',
        SetType.dropSet => 'DS',
        SetType.restPause => 'RP',
      };

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fila principal ─────────────────────────────────────────────
        Container(
          color: set.completed
              ? const Color(0xFFE53935).withOpacity(0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: [
              // Tipo de serie (toca para cambiar)
              GestureDetector(
                onTap: widget.onCycleType,
                child: SizedBox(
                  width: 26,
                  child: Center(
                    child: set.setType == SetType.normal
                        ? Icon(Icons.circle,
                            size: 6,
                            color: Colors.white.withOpacity(0.2))
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  _typeColor(set.setType).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _typeLabel(set.setType),
                              style: TextStyle(
                                  color: _typeColor(set.setType),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ),
              ),
              // Número
              SizedBox(
                width: 26,
                child: Text(
                  '${set.setNumber}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              // Peso
              Expanded(
                flex: 2,
                child: _InlineInput(
                  controller: _weightCtrl,
                  onChanged: _notifyWeight,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ),
              const SizedBox(width: 6),
              // Reps
              Expanded(
                flex: 2,
                child: _InlineInput(
                  controller: _repsCtrl,
                  onChanged: _notifyReps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // RPE / RIR
              Expanded(
                flex: 1,
                child: _InlineInput(
                  controller: _effortCtrl,
                  onChanged: _notifyEffort,
                  keyboardType: widget.useRir
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(
                          decimal: true),
                  inputFormatters: widget.useRir
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              // Checkbox completada
              GestureDetector(
                onTap: () =>
                    widget.onUpdate(set.copyWith(completed: !set.completed)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: set.completed
                        ? const Color(0xFFE53935)
                        : Colors.transparent,
                    border: Border.all(
                      color: set.completed
                          ? const Color(0xFFE53935)
                          : Colors.white24,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: set.completed
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              // Icono nota de serie
              GestureDetector(
                onTap: widget.onToggleNote,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: (set.notes?.isNotEmpty ?? false)
                      ? const Color(0xFFE53935)
                      : widget.noteOpen
                          ? Colors.white54
                          : Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),

        // ── Nota de serie (expandible) ─────────────────────────────────
        if (widget.noteOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(68, 2, 16, 4),
            child: TextField(
              controller: _setNotesCtrl,
              onChanged: _saveSetNote,
              maxLines: 1,
              style:
                  const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Nota de esta serie...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFFE53935), width: 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Campo inline ──────────────────────────────────────────────────────────────

class _InlineInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InlineInput({
    required this.controller,
    required this.onChanged,
    required this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFFE53935), width: 1),
        ),
      ),
    );
  }
}
