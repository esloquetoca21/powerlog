import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/exercise_def_model.dart';
import '../../models/exercise_model.dart';
import '../../widgets/primary_button.dart';

// ---------------------------------------------------------------------------
// CreateExerciseScreen
// ---------------------------------------------------------------------------

class CreateExerciseScreen extends StatefulWidget {
  /// null = create new exercise, non-null = edit existing
  final ExerciseDef? exerciseDef;

  const CreateExerciseScreen({super.key, this.exerciseDef});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ── Form state ─────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _videoUrlCtrl;

  ExerciseCategory? _category;
  String? _primaryMuscle;
  List<String> _secondaryMuscles = [];
  List<String> _disciplines = [];
  List<String> _equipment = [];
  int _difficulty = 2;

  // Dynamic instruction fields
  late List<TextEditingController> _instructionCtrls;

  // Dynamic cue fields
  late List<TextEditingController> _cueCtrls;

  // ── Validation errors ──────────────────────────────────────────────────────
  String? _nameError;
  String? _categoryError;
  String? _primaryMuscleError;

  @override
  void initState() {
    super.initState();
    final e = widget.exerciseDef;

    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _videoUrlCtrl = TextEditingController(text: e?.videoUrl ?? '');

    _category = e?.category;
    _primaryMuscle = e?.primaryMuscle;
    _secondaryMuscles = List.from(e?.secondaryMuscles ?? []);
    _disciplines = List.from(e?.disciplines ?? []);
    _equipment = List.from(e?.equipment ?? []);
    _difficulty = e?.difficulty ?? 2;

    // Instructions: at least one empty field
    final instructions = (e?.instructions.isNotEmpty == true)
        ? e!.instructions
        : [''];
    _instructionCtrls =
        instructions.map((s) => TextEditingController(text: s)).toList();

    // Cues: at least one empty field
    final cues =
        (e?.cues.isNotEmpty == true) ? e!.cues : [''];
    _cueCtrls =
        cues.map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _videoUrlCtrl.dispose();
    for (final c in _instructionCtrls) c.dispose();
    for (final c in _cueCtrls) c.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _categoryError = null;
      _primaryMuscleError = null;
    });

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'El nombre es obligatorio');
      valid = false;
    } else if (name.length < 3) {
      setState(
          () => _nameError = 'El nombre debe tener al menos 3 caracteres');
      valid = false;
    }

    if (_category == null) {
      setState(() => _categoryError = 'Selecciona una categoría');
      valid = false;
    }

    if (_primaryMuscle == null) {
      setState(
          () => _primaryMuscleError = 'Selecciona el músculo primario');
      valid = false;
    }

    return valid;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _saving = true);

    final instructions = _instructionCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final cues = _cueCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // TODO: replace placeholder uid with context.read<AuthService>().currentUser!.uid
    const String placeholderUid = 'current_user_uid';

    final def = ExerciseDef(
      id: widget.exerciseDef?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      instructions: instructions,
      primaryMuscle: _primaryMuscle!,
      secondaryMuscles: _secondaryMuscles,
      category: _category!,
      disciplines: _disciplines,
      equipment: _equipment,
      difficulty: _difficulty,
      videoUrl: _videoUrlCtrl.text.trim().isEmpty
          ? null
          : _videoUrlCtrl.text.trim(),
      cues: cues,
      isCustom: true,
      createdBy: widget.exerciseDef?.createdBy ?? placeholderUid,
      timestamp: widget.exerciseDef?.timestamp ??
          DateTime.now().toIso8601String(),
    );

    // TODO: call ExerciseService.saveExercise(def) when service is available
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ejercicio guardado'),
        backgroundColor: Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, def);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _difficultyLabel(int d) {
    switch (d) {
      case 1:
        return 'Principiante';
      case 2:
        return 'Básico';
      case 3:
        return 'Intermedio';
      case 4:
        return 'Avanzado';
      case 5:
        return 'Elite';
      default:
        return 'Básico';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.exerciseDef != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Editar ejercicio' : 'Nuevo ejercicio',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nombre ─────────────────────────────────────────────────
              const _SectionLabel('Nombre del ejercicio'),
              const SizedBox(height: 8),
              _DarkTextField(
                controller: _nameCtrl,
                hint: 'Ej. Sentadilla frontal',
                error: _nameError,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),

              const SizedBox(height: 20),

              // ── Categoría ──────────────────────────────────────────────
              const _SectionLabel('Categoría'),
              const SizedBox(height: 8),
              _DarkDropdown<ExerciseCategory>(
                value: _category,
                hint: 'Selecciona una categoría',
                error: _categoryError,
                items: ExerciseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(_categoryLabel(cat)),
                  );
                }).toList(),
                onChanged: (v) => setState(() {
                  _category = v;
                  _categoryError = null;
                }),
              ),

              const SizedBox(height: 20),

              // ── Músculo primario ───────────────────────────────────────
              const _SectionLabel('Músculo primario'),
              const SizedBox(height: 8),
              _DarkDropdown<String>(
                value: _primaryMuscle,
                hint: 'Selecciona el músculo principal',
                error: _primaryMuscleError,
                items: kAllMuscles.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (v) => setState(() {
                  _primaryMuscle = v;
                  _primaryMuscleError = null;
                  // Remove from secondary if selected as primary
                  if (v != null) _secondaryMuscles.remove(v);
                }),
              ),

              const SizedBox(height: 20),

              // ── Músculos secundarios ───────────────────────────────────
              const _SectionLabel('Músculos secundarios'),
              const SizedBox(height: 8),
              Text(
                'Selecciona los músculos que trabajan como secundarios.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllMuscles
                    .where((m) => m != _primaryMuscle)
                    .map((m) {
                  final selected = _secondaryMuscles.contains(m);
                  return _MultiChip(
                    label: m,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _secondaryMuscles.remove(m);
                      } else {
                        _secondaryMuscles.add(m);
                      }
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Descripción ────────────────────────────────────────────
              const _SectionLabel('Descripción (opcional)'),
              const SizedBox(height: 8),
              _DarkTextField(
                controller: _descriptionCtrl,
                hint: 'Describe brevemente el ejercicio...',
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              // ── Instrucciones ──────────────────────────────────────────
              const _SectionLabel('Instrucciones'),
              const SizedBox(height: 8),
              ..._buildInstructionFields(),
              const SizedBox(height: 8),
              _AddFieldButton(
                label: 'Añadir paso',
                onTap: () => setState(() {
                  _instructionCtrls
                      .add(TextEditingController());
                }),
              ),

              const SizedBox(height: 20),

              // ── Disciplinas ────────────────────────────────────────────
              const _SectionLabel('Disciplinas'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllDisciplines.map((d) {
                  final selected = _disciplines.contains(d);
                  return _MultiChip(
                    label: d,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _disciplines.remove(d);
                      } else {
                        _disciplines.add(d);
                      }
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Equipamiento ───────────────────────────────────────────
              const _SectionLabel('Equipamiento'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllEquipment.map((e) {
                  final selected = _equipment.contains(e);
                  return _MultiChip(
                    label: e,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _equipment.remove(e);
                      } else {
                        _equipment.add(e);
                      }
                    }),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Dificultad ─────────────────────────────────────────────
              const _SectionLabel('Dificultad'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _difficulty = star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        star <= _difficulty
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: star <= _difficulty
                            ? const Color(0xFFFFD600)
                            : Colors.white.withValues(alpha: 0.25),
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                _difficultyLabel(_difficulty),
                style: const TextStyle(
                    color: Color(0xFFFFD600),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),

              // ── URL de vídeo ───────────────────────────────────────────
              const _SectionLabel('URL de vídeo (opcional)'),
              const SizedBox(height: 8),
              _DarkTextField(
                controller: _videoUrlCtrl,
                hint: 'https://youtube.com/...',
                prefixIcon: const Icon(Icons.play_circle_outline,
                    color: Color(0xFFE53935), size: 20),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),

              // ── Cues técnicos ──────────────────────────────────────────
              const _SectionLabel('Cues técnicos'),
              const SizedBox(height: 4),
              Text(
                'Señales o recordatorios de técnica (máx. 8).',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12),
              ),
              const SizedBox(height: 8),
              ..._buildCueFields(),
              if (_cueCtrls.length < 8) ...[
                const SizedBox(height: 8),
                _AddFieldButton(
                  label: 'Añadir cue',
                  onTap: () => setState(() {
                    _cueCtrls.add(TextEditingController());
                  }),
                ),
              ],

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────────────
              PrimaryButton(
                label: 'Guardar ejercicio',
                onPressed: _save,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dynamic instruction fields ─────────────────────────────────────────────

  List<Widget> _buildInstructionFields() {
    return List.generate(_instructionCtrls.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DarkTextField(
                controller: _instructionCtrls[i],
                hint: 'Paso ${i + 1}...',
              ),
            ),
            if (_instructionCtrls.length > 1) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _instructionCtrls[i].dispose();
                  _instructionCtrls.removeAt(i);
                }),
                child: Icon(Icons.close,
                    color: Colors.white.withValues(alpha: 0.3), size: 18),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Dynamic cue fields ─────────────────────────────────────────────────────

  List<Widget> _buildCueFields() {
    return List.generate(_cueCtrls.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.record_voice_over_outlined,
                color: Colors.white.withValues(alpha: 0.3), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: _DarkTextField(
                controller: _cueCtrls[i],
                hint: 'Ej. "Pecho arriba, mirada al frente"',
              ),
            ),
            if (_cueCtrls.length > 1) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _cueCtrls[i].dispose();
                  _cueCtrls.removeAt(i);
                }),
                child: Icon(Icons.close,
                    color: Colors.white.withValues(alpha: 0.3), size: 18),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _categoryLabel(ExerciseCategory cat) {
    switch (cat) {
      case ExerciseCategory.squat:
        return 'Sentadilla';
      case ExerciseCategory.bench:
        return 'Banca';
      case ExerciseCategory.deadlift:
        return 'Peso muerto';
      case ExerciseCategory.row:
        return 'Remo';
      case ExerciseCategory.overhead:
        return 'Press OHP';
      case ExerciseCategory.olympic:
        return 'Olímpico';
      case ExerciseCategory.carry:
        return 'Acarreo';
      case ExerciseCategory.accessory:
        return 'Accesorio';
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable form widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? error;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.error,
    this.keyboardType,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null
                  ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null
                  ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                  : BorderSide(
                      color: Colors.white.withValues(alpha: 0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(
                color: Color(0xFFE53935), fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _DarkDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final String? error;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DarkDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? const Color(0xFFE53935)
                  : Colors.white.withValues(alpha: 0.06),
              width: error != null ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.4)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(
                color: Color(0xFFE53935), fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _MultiChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MultiChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE53935).withValues(alpha: 0.14)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFE53935)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddFieldButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Color(0xFFE53935), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
