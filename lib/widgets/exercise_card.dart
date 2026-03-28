import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_model.dart';
import '../models/set_model.dart';
import '../services/exercise_service.dart';
import '../services/exercise_stats_service.dart';
import '../services/session_service.dart';

class ExerciseCard extends StatefulWidget {
  final ExerciseModel exercise;
  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  static const _uuid = Uuid();

  bool _useRir = false;
  bool _showExerciseNotes = false;
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
    if (old.exercise.notes != widget.exercise.notes &&
        _exerciseNotesCtrl.text.isEmpty) {
      _exerciseNotesCtrl.text = widget.exercise.notes ?? '';
    }
  }

  @override
  void dispose() {
    _exerciseNotesCtrl.dispose();
    super.dispose();
  }

  void _persist(ExerciseModel updated) =>
      context.read<SessionService>().updateExercise(updated);

  void _showStatsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExerciseStatsSheet(exerciseName: widget.exercise.name),
    );
  }

  void _saveExerciseNotes(String value) => _persist(widget.exercise.copyWith(
        notes: value.trim().isEmpty ? null : value.trim(),
      ));

  void _updateSet(SetModel updated) {
    final sets = widget.exercise.sets
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    _persist(widget.exercise.copyWith(sets: sets));
  }

  void _removeSet(String setId) {
    var sets = widget.exercise.sets.where((s) => s.id != setId).toList();
    sets = sets
        .asMap()
        .entries
        .map((e) => e.value.copyWith(setNumber: e.key + 1))
        .toList();
    _persist(widget.exercise.copyWith(sets: sets));
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
    _persist(widget.exercise.copyWith(
        sets: [...widget.exercise.sets, newSet]));
  }

  void _cycleSetType(SetModel set) {
    final next =
        SetType.values[(set.setType.index + 1) % SetType.values.length];
    // Al volver a normal o fallo, limpiar sub-series
    final clear = next == SetType.normal || next == SetType.failure;
    _updateSet(clear
        ? set.copyWith(setType: next, clearSubSets: true)
        : set.copyWith(setType: next));
  }

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
          // ── Header ────────────────────────────────────────────────────
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
                  child: Text(ex.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
                // Toggle RPE / RIR
                GestureDetector(
                  onTap: () => setState(() => _useRir = !_useRir),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
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
                IconButton(
                  icon: Icon(Icons.notes_outlined,
                      color: _showExerciseNotes
                          ? const Color(0xFFE53935)
                          : Colors.white.withValues(alpha: 0.3),
                      size: 20),
                  onPressed: () =>
                      setState(() => _showExerciseNotes = !_showExerciseNotes),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.bar_chart,
                      color: Colors.white.withValues(alpha: 0.3), size: 20),
                  onPressed: _showStatsSheet,
                  tooltip: 'Estadísticas',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.white.withValues(alpha: 0.3), size: 20),
                  onPressed: () =>
                      context.read<SessionService>().removeExercise(ex.id),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // ── Notas del ejercicio ──────────────────────────────────────
          if (_showExerciseNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _exerciseNotesCtrl,
                onChanged: _saveExerciseNotes,
                maxLines: 2,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Notas del ejercicio...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
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

          // ── Cabecera de columnas ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Row(
              children: [
                const SizedBox(width: 26), // tipo
                const SizedBox(width: 26), // número
                _colHeader('Peso', flex: 2),
                const SizedBox(width: 6),
                _colHeader('Reps', flex: 2),
                const SizedBox(width: 6),
                _colHeader(_useRir ? 'RIR' : 'RPE', flex: 1),
                const SizedBox(width: 6),
                const SizedBox(width: 32), // checkbox
                const SizedBox(width: 28), // nota
              ],
            ),
          ),

          // ── Series (con swipe-to-delete) ─────────────────────────────
          ...ex.sets.map((set) {
            final noteOpen = _setNoteExpanded[set.id] ?? false;
            return Dismissible(
              key: Key('set_${set.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFE53935), size: 20),
              ),
              onDismissed: (_) => _removeSet(set.id),
              child: _SetBlock(
                set: set,
                useRir: _useRir,
                noteOpen: noteOpen,
                onUpdate: _updateSet,
                onRemove: () => _removeSet(set.id),
                onCycleType: () => _cycleSetType(set),
                onToggleNote: () =>
                    setState(() => _setNoteExpanded[set.id] = !noteOpen),
              ),
            );
          }),

          // ── Añadir serie ─────────────────────────────────────────────
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
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      );

  Color _categoryColor(ExerciseCategory cat) => switch (cat) {
        ExerciseCategory.squat => Colors.blueAccent,
        ExerciseCategory.bench => Colors.greenAccent,
        ExerciseCategory.deadlift => const Color(0xFFE53935),
        ExerciseCategory.row => Colors.tealAccent,
        ExerciseCategory.overhead => Colors.purpleAccent,
        ExerciseCategory.olympic => Colors.amberAccent,
        ExerciseCategory.carry => Colors.cyanAccent,
        ExerciseCategory.accessory => Colors.orangeAccent,
      };
}

// ── Set block ────────────────────────────────────────────────────────────────

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
  late TextEditingController _effortCtrl;
  late TextEditingController _setNotesCtrl;
  List<TextEditingController> _subWeightCtrls = [];
  List<TextEditingController> _subRepsCtrls = [];

  @override
  void initState() {
    super.initState();
    final w = widget.set.weight;
    _weightCtrl = TextEditingController(
        text: w == 0
            ? ''
            : (w == w.truncateToDouble()
                ? w.toInt().toString()
                : w.toString()));
    _repsCtrl = TextEditingController(
        text: widget.set.reps == 0 ? '' : widget.set.reps.toString());
    _effortCtrl = TextEditingController(text: _effortText());
    _setNotesCtrl =
        TextEditingController(text: widget.set.notes ?? '');
    _initSubControllers();
  }

  void _initSubControllers() {
    final subs = widget.set.subSets ?? [];
    _subWeightCtrls = subs.map((s) {
      final w = s.weight;
      return TextEditingController(
          text: w == 0
              ? ''
              : (w == w.truncateToDouble()
                  ? w.toInt().toString()
                  : w.toString()));
    }).toList();
    _subRepsCtrls = subs
        .map((s) => TextEditingController(
            text: s.reps == 0 ? '' : s.reps.toString()))
        .toList();
  }

  void _disposeSubControllers() {
    for (final c in _subWeightCtrls) { c.dispose(); }
    for (final c in _subRepsCtrls) { c.dispose(); }
    _subWeightCtrls = [];
    _subRepsCtrls = [];
  }

  @override
  void didUpdateWidget(_SetBlock old) {
    super.didUpdateWidget(old);
    if (old.useRir != widget.useRir) {
      _effortCtrl.text = _effortText();
    }
    final oldCount = old.set.subSets?.length ?? 0;
    final newCount = widget.set.subSets?.length ?? 0;
    if (oldCount != newCount) {
      _disposeSubControllers();
      _initSubControllers();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _effortCtrl.dispose();
    _setNotesCtrl.dispose();
    _disposeSubControllers();
    super.dispose();
  }

  String _effortText() {
    if (widget.useRir) return widget.set.rir?.toString() ?? '';
    final rpe = widget.set.rpe;
    if (rpe == null) return '';
    return rpe == rpe.truncateToDouble()
        ? rpe.toInt().toString()
        : rpe.toString();
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
      widget.onUpdate(widget.set.copyWith(rir: i, clearRpe: true));
    } else {
      final d = double.tryParse(v.replaceAll(',', '.'));
      widget.onUpdate(widget.set.copyWith(rpe: d, clearRir: true));
    }
  }

  void _saveSetNote(String v) => widget.onUpdate(widget.set.copyWith(
      notes: v.trim().isEmpty ? null : v.trim()));

  // ── Sub-sets ────────────────────────────────────────────────────────

  void _addSubSet() {
    final subs = widget.set.subSets ?? [];
    final last = subs.isNotEmpty ? subs.last : null;
    final newSub = SubSet(
      weight: last?.weight ?? widget.set.weight,
      reps: last?.reps ?? 5,
    );
    widget.onUpdate(widget.set.copyWith(subSets: [...subs, newSub]));
  }

  void _removeSubSet(int index) {
    final subs = List<SubSet>.from(widget.set.subSets ?? [])
      ..removeAt(index);
    widget.onUpdate(subs.isEmpty
        ? widget.set.copyWith(clearSubSets: true)
        : widget.set.copyWith(subSets: subs));
  }

  void _notifySubWeight(int index, String v) {
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d == null) return;
    final subs = List<SubSet>.from(widget.set.subSets ?? []);
    if (index < subs.length) {
      subs[index] = subs[index].copyWith(weight: d);
      widget.onUpdate(widget.set.copyWith(subSets: subs));
    }
  }

  void _notifySubReps(int index, String v) {
    final i = int.tryParse(v);
    if (i == null) return;
    final subs = List<SubSet>.from(widget.set.subSets ?? []);
    if (index < subs.length) {
      subs[index] = subs[index].copyWith(reps: i);
      widget.onUpdate(widget.set.copyWith(subSets: subs));
    }
  }

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
    final subs = set.subSets ?? [];
    final isDropSet = set.setType == SetType.dropSet;
    final isRestPause = set.setType == SetType.restPause;
    final showSubSection = isDropSet || isRestPause;
    final canAddSub = isDropSet || (isRestPause && subs.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fila principal ───────────────────────────────────────────
        Container(
          color: set.completed
              ? const Color(0xFFE53935).withValues(alpha: 0.05)
              : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Row(
            children: [
              // Tipo (toca para ciclar)
              GestureDetector(
                onTap: widget.onCycleType,
                child: SizedBox(
                  width: 26,
                  child: Center(
                    child: set.setType == SetType.normal
                        ? Icon(Icons.circle,
                            size: 6,
                            color: Colors.white.withValues(alpha: 0.2))
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: _typeColor(set.setType)
                                  .withValues(alpha: 0.15),
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
                child: Text('${set.setNumber}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
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
                onTap: () => widget
                    .onUpdate(set.copyWith(completed: !set.completed)),
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
              // Nota de serie
              GestureDetector(
                onTap: widget.onToggleNote,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: (set.notes?.isNotEmpty ?? false)
                      ? const Color(0xFFE53935)
                      : widget.noteOpen
                          ? Colors.white54
                          : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),

        // ── Nota de serie ────────────────────────────────────────────
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
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
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

        // ── Sub-series (Drop Set / Rest-Pause) ───────────────────────
        if (showSubSection) ...[
          ...subs.asMap().entries.map((entry) {
            final i = entry.key;
            return _SubSetRow(
              index: i,
              isDropSet: isDropSet,
              isLast: i == subs.length - 1 && !canAddSub,
              weightCtrl: _subWeightCtrls[i],
              repsCtrl: _subRepsCtrls[i],
              onWeightChanged: (v) => _notifySubWeight(i, v),
              onRepsChanged: (v) => _notifySubReps(i, v),
              onRemove: () => _removeSubSet(i),
            );
          }),
          if (canAddSub)
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 4, 16, 6),
              child: GestureDetector(
                onTap: _addSubSet,
                child: Row(
                  children: [
                    Container(
                        width: 1,
                        height: 14,
                        color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.add,
                      size: 14,
                      color: isDropSet
                          ? Colors.orangeAccent.withValues(alpha: 0.7)
                          : Colors.purpleAccent.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDropSet ? 'Añadir drop' : 'Añadir pausa',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDropSet
                            ? Colors.orangeAccent.withValues(alpha: 0.7)
                            : Colors.purpleAccent.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── Sub-set row ──────────────────────────────────────────────────────────────

class _SubSetRow extends StatelessWidget {
  final int index;
  final bool isDropSet;
  final bool isLast;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onRepsChanged;
  final VoidCallback onRemove;

  const _SubSetRow({
    required this.index,
    required this.isDropSet,
    required this.isLast,
    required this.weightCtrl,
    required this.repsCtrl,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDropSet ? Colors.orangeAccent : Colors.purpleAccent;
    final label = isDropSet ? 'D${index + 1}' : 'RP';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Row(
        children: [
          // Conector visual
          SizedBox(
            width: 26,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 1,
                    height: 12,
                    color: Colors.white.withValues(alpha: 0.1)),
                Icon(
                  isLast
                      ? Icons.subdirectory_arrow_right
                      : Icons.more_vert,
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          // Badge
          Container(
            width: 26,
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
          // Peso
          Expanded(
            flex: 2,
            child: _InlineInput(
              controller: weightCtrl,
              onChanged: onWeightChanged,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              accentColor: color,
            ),
          ),
          const SizedBox(width: 6),
          // Reps
          Expanded(
            flex: 2,
            child: _InlineInput(
              controller: repsCtrl,
              onChanged: onRepsChanged,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              accentColor: color,
            ),
          ),
          const SizedBox(width: 6),
          // Espacio RPE/RIR (alineación)
          const Expanded(flex: 1, child: SizedBox()),
          const SizedBox(width: 6),
          // Eliminar sub-serie
          SizedBox(
            width: 32,
            child: GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close,
                  color: Colors.white.withValues(alpha: 0.25), size: 16),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// ── Inline field ─────────────────────────────────────────────────────────────

class _InlineInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color? accentColor;

  const _InlineInput({
    required this.controller,
    required this.onChanged,
    required this.keyboardType,
    this.inputFormatters,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? const Color(0xFFE53935);
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
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1),
        ),
      ),
    );
  }
}

// ── Exercise stats bottom sheet ───────────────────────────────────────────────

class _ExerciseStatsSheet extends StatefulWidget {
  final String exerciseName;

  const _ExerciseStatsSheet({required this.exerciseName});

  @override
  State<_ExerciseStatsSheet> createState() => _ExerciseStatsSheetState();
}

class _ExerciseStatsSheetState extends State<_ExerciseStatsSheet> {
  late Future<ExerciseStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ExerciseStats> _load() async {
    final sessions = context.read<SessionService>().sessions;
    return ExerciseStatsService().calculate(widget.exerciseName, sessions, 0);
  }

  String _fmtDate(DateTime d) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Also grab notes from ExerciseService if available
    final exerciseSvc = context.read<ExerciseService>();
    final defId = exerciseSvc.allExercises
        .where((e) => e.name.toLowerCase() == widget.exerciseName.toLowerCase())
        .map((e) => e.id)
        .firstOrNull;
    final notes = defId != null
        ? exerciseSvc.getPref(defId).notes
        : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.7,
      minChildSize: 0.35,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.bar_chart,
                    color: Color(0xFFE53935), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.exerciseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: FutureBuilder<ExerciseStats>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE53935), strokeWidth: 2),
                  );
                }

                final stats = snapshot.data!;

                if (stats.totalSets == 0) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            Text(
                              'Sin historial todavía',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SheetSection(
                          icon: Icons.notes_outlined,
                          title: 'Mis notas',
                          child: Text(notes,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  height: 1.5)),
                        ),
                      ],
                    ],
                  );
                }

                // Last set (most recent in allSets, sorted chronologically)
                final lastSet = stats.allSets.isNotEmpty
                    ? stats.allSets.last
                    : null;

                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Row: PR + 1RM
                    Row(
                      children: [
                        _SheetStatCard(
                          label: 'Récord personal',
                          value: stats.personalRecord != null
                              ? '${stats.personalRecord!.weight.toStringAsFixed(1)} kg'
                              : '—',
                          sub: stats.personalRecord != null
                              ? '× ${stats.personalRecord!.reps} reps'
                                  '${stats.prDate != null ? '\n${_fmtDate(stats.prDate!)}' : ''}'
                              : '',
                          icon: Icons.emoji_events_outlined,
                          highlight: true,
                        ),
                        const SizedBox(width: 10),
                        _SheetStatCard(
                          label: '1RM estimado',
                          value: stats.maxEstimated1RM > 0
                              ? '${stats.maxEstimated1RM.toStringAsFixed(1)} kg'
                              : '—',
                          sub: 'Fórmula Epley',
                          icon: Icons.trending_up,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row: Last used + last performed
                    Row(
                      children: [
                        _SheetStatCard(
                          label: 'Último uso',
                          value: lastSet != null
                              ? '${lastSet.weight.toStringAsFixed(1)} kg'
                              : '—',
                          sub: lastSet != null
                              ? '× ${lastSet.reps} reps'
                              : '',
                          icon: Icons.history,
                        ),
                        const SizedBox(width: 10),
                        _SheetStatCard(
                          label: 'Última sesión',
                          value: stats.lastPerformed != null
                              ? _fmtDate(stats.lastPerformed!)
                              : '—',
                          sub: '${stats.totalSets} series en total',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),

                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SheetSection(
                        icon: Icons.notes_outlined,
                        title: 'Mis notas',
                        child: Text(notes,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                height: 1.5)),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final bool highlight;

  const _SheetStatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFE53935).withValues(alpha: 0.08)
              : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(12),
          border: highlight
              ? Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 14,
                    color: highlight
                        ? const Color(0xFFE53935)
                        : Colors.white.withValues(alpha: 0.35)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: highlight
                        ? const Color(0xFFE53935)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            if (sub.isNotEmpty)
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SheetSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
