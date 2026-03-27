import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/exercise_model.dart';
import '../../models/session_model.dart';
import '../../models/set_model.dart';

Color _setTypeColor(SetType t) => switch (t) {
      SetType.normal => Colors.transparent,
      SetType.failure => const Color(0xFFE53935),
      SetType.dropSet => Colors.orangeAccent,
      SetType.restPause => Colors.purpleAccent,
    };

String _setTypeLabel(SetType t) => switch (t) {
      SetType.normal => '',
      SetType.failure => 'F',
      SetType.dropSet => 'DS',
      SetType.restPause => 'RP',
    };
import '../../services/session_service.dart';
import '../../widgets/add_exercise_sheet.dart';

class SavedSessionScreen extends StatefulWidget {
  final SessionModel session;
  const SavedSessionScreen({super.key, required this.session});

  @override
  State<SavedSessionScreen> createState() => _SavedSessionScreenState();
}

class _SavedSessionScreenState extends State<SavedSessionScreen> {
  static const _uuid = Uuid();

  bool _editing = false;
  bool _saving = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _notesCtrl;
  late List<ExerciseModel> _exercises;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.session);
  }

  void _initControllers(SessionModel s) {
    _titleCtrl = TextEditingController(text: s.title);
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _exercises = s.exercises.map((e) => e.copyWith(
      sets: List<SetModel>.from(e.sets),
    )).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _startEdit() => setState(() => _editing = true);

  void _cancelEdit() {
    _titleCtrl.text = widget.session.title;
    _notesCtrl.text = widget.session.notes ?? '';
    _exercises = widget.session.exercises.map((e) => e.copyWith(
      sets: List<SetModel>.from(e.sets),
    )).toList();
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('El nombre no puede estar vacío');
      return;
    }
    setState(() => _saving = true);

    final updated = widget.session.copyWith(
      title: title,
      exercises: _exercises,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      await context.read<SessionService>().updateSession(updated);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      _showSnack('Sesión actualizada');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Error al guardar');
    }
  }

  Future<void> _deleteSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '¿Seguro? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<SessionService>().deleteSession(widget.session.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _addSetToExercise(int exerciseIndex) {
    final ex = _exercises[exerciseIndex];
    final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
    final newSet = SetModel(
      id: _uuid.v4(),
      setNumber: ex.sets.length + 1,
      weight: lastSet?.weight ?? 0,
      reps: lastSet?.reps ?? 5,
      timestamp: DateTime.now(),
    );
    setState(() {
      _exercises[exerciseIndex] = ex.copyWith(
        sets: [...ex.sets, newSet],
      );
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    final ex = _exercises[exerciseIndex];
    final newSets = List<SetModel>.from(ex.sets)..removeAt(setIndex);
    final renumbered = newSets
        .asMap()
        .entries
        .map((e) => e.value.copyWith(setNumber: e.key + 1))
        .toList();
    setState(() {
      _exercises[exerciseIndex] = ex.copyWith(sets: renumbered);
    });
  }

  void _updateSet(int exerciseIndex, int setIndex, SetModel updated) {
    final ex = _exercises[exerciseIndex];
    final newSets = List<SetModel>.from(ex.sets)..[setIndex] = updated;
    setState(() {
      _exercises[exerciseIndex] = ex.copyWith(sets: newSets);
    });
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _showAddExercise() {
    // Temporarily set activeSession so AddExerciseSheet works,
    // then capture the added exercise from service
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddExerciseSheetEdit(
        onAdd: (exercise) {
          setState(() => _exercises.add(exercise));
        },
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final totalSets = _exercises.fold<int>(0, (s, e) => s + e.sets.length);
    final totalVolume = _exercises.fold<int>(
        0, (s, e) => s + e.totalVolume);
    final durationStr = session.duration != null
        ? '${session.duration!.inMinutes} min'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: _editing
            ? TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nombre de la sesión',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              )
            : Text(session.title,
                style: const TextStyle(fontSize: 16)),
        actions: _editing
            ? [
                TextButton(
                  onPressed: _saving ? null : _cancelEdit,
                  child: Text('Cancelar',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5))),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE53935)),
                        )
                      : const Text('Guardar',
                          style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600)),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _startEdit,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSession,
                  tooltip: 'Eliminar',
                ),
              ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fecha y stats ──────────────────────────────────────────
            Text(
              _formatDate(session.date),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatChip(
                    icon: Icons.timer_outlined, label: durationStr ?? '—'),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.fitness_center,
                    label: '${_exercises.length} ejercicios'),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.repeat, label: '$totalSets series'),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.scale_outlined,
                    label: '${totalVolume}kg'),
              ],
            ),

            const SizedBox(height: 24),

            // ── Ejercicios ────────────────────────────────────────────
            _SectionTitle('Ejercicios'),
            const SizedBox(height: 10),

            ..._exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final ex = entry.value;
              return _ExerciseBlock(
                exercise: ex,
                editing: _editing,
                onAddSet: () => _addSetToExercise(i),
                onRemoveSet: (si) => _removeSet(i, si),
                onUpdateSet: (si, s) => _updateSet(i, si, s),
                onRemoveExercise: () => _removeExercise(i),
              );
            }),

            if (_editing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showAddExercise,
                icon: const Icon(Icons.add, color: Color(0xFFE53935)),
                label: const Text('Añadir ejercicio',
                    style: TextStyle(color: Color(0xFFE53935))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE53935)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Notas ─────────────────────────────────────────────────
            _SectionTitle('Notas'),
            const SizedBox(height: 10),
            _editing
                ? TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Sensaciones, técnica, ajustes...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE53935), width: 1.5),
                      ),
                    ),
                  )
                : session.notes != null
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(session.notes!,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14,
                                height: 1.5)),
                      )
                    : Text('Sin notas',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 14)),

            // ── AI insights ───────────────────────────────────────────
            if (session.aiInsights != null) ...[
              const SizedBox(height: 24),
              _SectionTitle('Análisis IA'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFFE53935), size: 14),
                        const SizedBox(width: 6),
                        Text('Claude',
                            style: TextStyle(
                                color: const Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(session.aiInsights!,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            height: 1.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = [
      '', 'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo'
    ];
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${weekdays[d.weekday]}, ${d.day} de ${months[d.month]} de ${d.year}';
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600));
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Exercise block ────────────────────────────────────────────────────────────

class _ExerciseBlock extends StatelessWidget {
  final ExerciseModel exercise;
  final bool editing;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int, SetModel) onUpdateSet;
  final VoidCallback onRemoveExercise;

  const _ExerciseBlock({
    required this.exercise,
    required this.editing,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateSet,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(exercise.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                if (editing)
                  IconButton(
                    onPressed: onRemoveExercise,
                    icon: Icon(Icons.close,
                        color: Colors.white.withOpacity(0.3), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('#',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11)),
                ),
                Expanded(
                  child: Text('kg',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11)),
                ),
                Expanded(
                  child: Text('reps',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11)),
                ),
                SizedBox(
                  width: 52,
                  child: Text('RPE',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11)),
                ),
                if (editing) const SizedBox(width: 28),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Sets
          ...exercise.sets.asMap().entries.map((entry) {
            final i = entry.key;
            final set = entry.value;
            return _SetRow(
              set: set,
              editing: editing,
              onRemove: () => onRemoveSet(i),
              onUpdate: (updated) => onUpdateSet(i, updated),
            );
          }),

          // Add set button
          if (editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: GestureDetector(
                onTap: onAddSet,
                child: Row(
                  children: [
                    Icon(Icons.add,
                        color: const Color(0xFFE53935).withOpacity(0.7),
                        size: 16),
                    const SizedBox(width: 4),
                    Text('Añadir serie',
                        style: TextStyle(
                            color: const Color(0xFFE53935).withOpacity(0.7),
                            fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Set row ───────────────────────────────────────────────────────────────────

class _SetRow extends StatefulWidget {
  final SetModel set;
  final bool editing;
  final VoidCallback onRemove;
  final ValueChanged<SetModel> onUpdate;

  const _SetRow({
    required this.set,
    required this.editing,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _rpeCtrl;

  @override
  void initState() {
    super.initState();
    final w = widget.set.weight;
    _weightCtrl = TextEditingController(
        text: w == w.truncateToDouble() ? w.toInt().toString() : w.toString());
    _repsCtrl =
        TextEditingController(text: widget.set.reps.toString());
    _rpeCtrl = TextEditingController(
        text: widget.set.rpe?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _rpeCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final weight =
        double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ??
            widget.set.weight;
    final reps =
        int.tryParse(_repsCtrl.text) ?? widget.set.reps;
    final rpe = _rpeCtrl.text.isNotEmpty
        ? double.tryParse(_rpeCtrl.text.replaceAll(',', '.'))
        : null;
    widget.onUpdate(
        widget.set.copyWith(weight: weight, reps: reps, rpe: rpe));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editing) {
      // View mode
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('${widget.set.setNumber}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13)),
            ),
            Expanded(
              child: Text(
                '${widget.set.weight % 1 == 0 ? widget.set.weight.toInt() : widget.set.weight} kg',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text('${widget.set.reps} reps',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13)),
            ),
            SizedBox(
              width: 60,
              child: Text(
                widget.set.rir != null
                    ? 'RIR ${widget.set.rir}'
                    : widget.set.rpe != null
                        ? 'RPE ${widget.set.rpe}'
                        : '—',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ),
            if (widget.set.setType != SetType.normal)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _setTypeColor(widget.set.setType).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _setTypeLabel(widget.set.setType),
                  style: TextStyle(
                      color: _setTypeColor(widget.set.setType),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }

    // Edit mode
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${widget.set.setNumber}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13)),
          ),
          Expanded(
            child: _InlineField(
                controller: _weightCtrl,
                hint: 'kg',
                onChanged: (_) => _notify()),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _InlineField(
                controller: _repsCtrl,
                hint: 'reps',
                onChanged: (_) => _notify(),
                isInt: true),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 46,
            child: _InlineField(
                controller: _rpeCtrl,
                hint: 'RPE',
                onChanged: (_) => _notify()),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onRemove,
            child: Icon(Icons.remove_circle_outline,
                color: Colors.white.withOpacity(0.25), size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Inline field ──────────────────────────────────────────────────────────────

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isInt;

  const _InlineField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isInt
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      style: const TextStyle(color: Colors.white, fontSize: 13),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFE53935), width: 1),
        ),
      ),
    );
  }
}

// ── Add exercise sheet (edit mode) ────────────────────────────────────────────

class _AddExerciseSheetEdit extends StatefulWidget {
  final ValueChanged<ExerciseModel> onAdd;
  const _AddExerciseSheetEdit({required this.onAdd});

  @override
  State<_AddExerciseSheetEdit> createState() =>
      _AddExerciseSheetEditState();
}

class _AddExerciseSheetEditState extends State<_AddExerciseSheetEdit> {
  static const _uuid = Uuid();
  final _searchCtrl = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.squat;

  static const Map<ExerciseCategory, List<String>> _exercises =
      AddExerciseSheet.exercises;

  List<String> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _exercises[_category] ?? [];
    return _exercises.values
        .expand((l) => l)
        .where((e) => e.toLowerCase().contains(q))
        .toList();
  }

  void _select(String name) {
    final ex = ExerciseModel(
      id: _uuid.v4(),
      name: name,
      category: _category,
      sets: [
        SetModel(
          id: _uuid.v4(),
          setNumber: 1,
          weight: 0,
          reps: 5,
          timestamp: DateTime.now(),
        )
      ],
    );
    widget.onAdd(ex);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _catLabel(ExerciseCategory c) => switch (c) {
        ExerciseCategory.squat => 'Sentadilla',
        ExerciseCategory.bench => 'Banca',
        ExerciseCategory.deadlift => 'Peso muerto',
        ExerciseCategory.accessory => 'Accesorio',
      };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Añadir ejercicio',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle:
                    TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ExerciseCategory.values.map((cat) {
                final sel = cat == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_catLabel(cat)),
                    selected: sel,
                    onSelected: (_) =>
                        setState(() => _category = cat),
                    selectedColor: const Color(0xFFE53935),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.white60,
                        fontSize: 13),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: const Icon(Icons.fitness_center,
                    color: Color(0xFFE53935), size: 20),
                title: Text(_filtered[i],
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
                onTap: () => _select(_filtered[i]),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
