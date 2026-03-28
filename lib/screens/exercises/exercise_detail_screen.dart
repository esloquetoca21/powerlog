import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_def_model.dart';
import '../../models/exercise_pref_model.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../widgets/muscle_map_widget.dart';
import 'create_exercise_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseDef exerciseDef;

  const ExerciseDetailScreen({super.key, required this.exerciseDef});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late ExercisePref _pref;

  @override
  void initState() {
    super.initState();
    _pref = context.read<ExerciseService>().getPref(widget.exerciseDef.id);
  }

  String? get _uid => context.read<AuthService>().currentUser?.uid;

  // ── Favorite ────────────────────────────────────────────────────────────────

  Future<void> _showFavoriteSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FavoriteSheet(
        currentPref: _pref,
        onSelect: (group, color) async {
          final uid = _uid;
          if (uid == null) return;
          final updated = _pref.copyWith(
            isFavorite: true,
            favoriteGroup: group,
            favoriteColor: color,
            updatedAt: DateTime.now(),
          );
          await context.read<ExerciseService>().updatePref(updated, uid);
          if (mounted) setState(() => _pref = updated);
        },
        onRemove: () async {
          final uid = _uid;
          if (uid == null) return;
          final updated = _pref.copyWith(
            isFavorite: false,
            clearFavoriteGroup: true,
            clearFavoriteColor: true,
            updatedAt: DateTime.now(),
          );
          await context.read<ExerciseService>().updatePref(updated, uid);
          if (mounted) setState(() => _pref = updated);
        },
      ),
    );
  }

  // ── Hide ────────────────────────────────────────────────────────────────────

  Future<void> _confirmHide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Ocultar ejercicio',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'El ejercicio "${widget.exerciseDef.name}" no aparecerá en la biblioteca. '
          'Puedes mostrarlo de nuevo desde los filtros.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ocultar',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final uid = _uid;
    if (uid == null) return;
    final updated = _pref.copyWith(isHidden: true, updatedAt: DateTime.now());
    await context.read<ExerciseService>().updatePref(updated, uid);
    if (mounted) {
      setState(() => _pref = updated);
      Navigator.of(context).pop();
    }
  }

  // ── Edit / Delete ────────────────────────────────────────────────────────────

  Future<void> _editExercise() async {
    final result = await Navigator.of(context).push<ExerciseDef>(
      MaterialPageRoute(
        builder: (_) =>
            CreateExerciseScreen(exerciseDef: widget.exerciseDef),
      ),
    );
    if (result != null && mounted) {
      final uid = _uid;
      if (uid != null) {
        await context.read<ExerciseService>().saveCustomExercise(result, uid);
      }
      // Pop back to library — the library will reload
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteExercise() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar ejercicio',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar "${widget.exerciseDef.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
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
    final uid = _uid;
    if (uid == null) return;
    await context
        .read<ExerciseService>()
        .deleteCustomExercise(widget.exerciseDef.id, uid);
    if (mounted) Navigator.of(context).pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final def = widget.exerciseDef;
    final isFav = _pref.isFavorite;
    final favColor = isFav && _pref.favoriteColorValue != null
        ? Color(_pref.favoriteColorValue!)
        : Colors.white.withValues(alpha: 0.5);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(def.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFE53935),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Notas'),
              Tab(text: 'Vídeo'),
            ],
          ),
          actions: [
            // Favorite button
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? favColor : Colors.white.withValues(alpha: 0.5),
              ),
              tooltip: 'Favorito',
              onPressed: _showFavoriteSheet,
            ),
            // Hide button
            IconButton(
              icon: Icon(
                _pref.isHidden ? Icons.visibility_off : Icons.visibility_outlined,
                color: _pref.isHidden
                    ? const Color(0xFFE53935)
                    : Colors.white.withValues(alpha: 0.5),
              ),
              tooltip: _pref.isHidden ? 'Oculto' : 'Ocultar',
              onPressed: _pref.isHidden ? null : _confirmHide,
            ),
            // 3-dot menu (only for custom exercises)
            if (def.isCustom)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.6)),
                color: const Color(0xFF222222),
                onSelected: (v) {
                  if (v == 'edit') _editExercise();
                  if (v == 'delete') _deleteExercise();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                      SizedBox(width: 10),
                      Text('Editar', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFE53935)),
                      SizedBox(width: 10),
                      Text('Eliminar',
                          style: TextStyle(color: Color(0xFFE53935))),
                    ]),
                  ),
                ],
              ),
          ],
        ),
        body: TabBarView(
          children: [
            _InfoTab(def: def),
            const _PlaceholderTab(label: 'Estadísticas'),
            _NotesTab(pref: _pref, def: def, onPrefUpdated: (p) {
              if (mounted) setState(() => _pref = p);
            }),
            const _PlaceholderTab(label: 'Vídeo'),
          ],
        ),
      ),
    );
  }
}

// ── Tab Info ─────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final ExerciseDef def;

  const _InfoTab({required this.def});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Name block
        Text(
          def.name,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (def.nameEn != null) ...[
          const SizedBox(height: 4),
          Text(
            def.nameEn!,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          ),
        ],

        const SizedBox(height: 12),

        // Difficulty stars
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < def.difficulty ? Icons.star : Icons.star_border,
              size: 18,
              color: i < def.difficulty
                  ? const Color(0xFFE53935)
                  : Colors.white24,
            );
          }),
        ),

        const SizedBox(height: 20),

        // Muscle map
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MuscleMapWidget(
            primaryMuscle: def.primaryMuscle,
            secondaryMuscles: def.secondaryMuscles,
            height: 200,
          ),
        ),

        const SizedBox(height: 8),

        // Color legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: const Color(0xFFE74C3C), label: 'Primario'),
            const SizedBox(width: 16),
            _Legend(color: const Color(0xFFE67E22), label: 'Secundario'),
          ],
        ),

        const SizedBox(height: 24),

        // Description
        if (def.description != null && def.description!.isNotEmpty) ...[
          _SectionHeader('Descripción'),
          const SizedBox(height: 8),
          Text(
            def.description!,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), height: 1.5),
          ),
          const SizedBox(height: 24),
        ],

        // Muscle chips
        _SectionHeader('Músculos'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MuscleChip(label: def.primaryMuscle, primary: true),
            for (final m in def.secondaryMuscles)
              _MuscleChip(label: m, primary: false),
          ],
        ),

        const SizedBox(height: 20),

        // Equipment & Disciplines
        if (def.equipment.isNotEmpty) ...[
          _SectionHeader('Equipamiento'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final e in def.equipment) _InfoChip(label: e),
            ],
          ),
          const SizedBox(height: 20),
        ],

        if (def.disciplines.isNotEmpty) ...[
          _SectionHeader('Disciplinas'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final d in def.disciplines) _InfoChip(label: d),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Instructions
        if (def.instructions.isNotEmpty) ...[
          _SectionHeader('Ejecución'),
          const SizedBox(height: 10),
          for (int i = 0; i < def.instructions.length; i++)
            _InstructionRow(number: i + 1, text: def.instructions[i]),
          const SizedBox(height: 20),
        ],

        // Cues
        if (def.cues.isNotEmpty) ...[
          _SectionHeader('Cues técnicos'),
          const SizedBox(height: 8),
          for (final cue in def.cues)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('→  ',
                      style: TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(cue,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8))),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],

        // RPE table
        if (def.recommendedRpe.isNotEmpty) ...[
          _SectionHeader('RPE recomendado'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                for (int i = 0; i < def.recommendedRpe.entries.length; i++)
                  _RpeRow(
                    level: def.recommendedRpe.entries.elementAt(i).key,
                    rpe: def.recommendedRpe.entries.elementAt(i).value,
                    last: i == def.recommendedRpe.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Tags
        if (def.tags.isNotEmpty) ...[
          _SectionHeader('Etiquetas'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [for (final t in def.tags) _InfoChip(label: '#$t')],
          ),
        ],
      ],
    );
  }
}

// ── Tab Notas ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatefulWidget {
  final ExercisePref pref;
  final ExerciseDef def;
  final ValueChanged<ExercisePref> onPrefUpdated;

  const _NotesTab({
    required this.pref,
    required this.def,
    required this.onPrefUpdated,
  });

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  bool _saving = false;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.pref.notes);
    if (widget.pref.updatedAt != null) _lastSaved = widget.pref.updatedAt;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), _save);
  }

  Future<void> _save() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    final updated = widget.pref.copyWith(
      notes: _ctrl.text,
      updatedAt: DateTime.now(),
    );
    await context.read<ExerciseService>().updatePref(updated, uid);
    if (mounted) {
      setState(() {
        _saving = false;
        _lastSaved = updated.updatedAt;
      });
      widget.onPrefUpdated(updated);
    }
  }

  String _formatDate(DateTime d) {
    final months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month]} ${d.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis notas',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: _onChanged,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                    color: Colors.white, height: 1.55, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'Añade tus cues personales, sensaciones, ajustes...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 14),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_saving)
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFFE53935)),
                    ),
                    const SizedBox(width: 6),
                    Text('Guardando...',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12)),
                  ],
                )
              else if (_lastSaved != null)
                Text(
                  'Guardado el ${_formatDate(_lastSaved!)}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab placeholder ──────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final String label;

  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_outlined,
              size: 48, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'Próximamente',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Favorite bottom sheet ────────────────────────────────────────────────────

class _FavoriteSheet extends StatelessWidget {
  final ExercisePref currentPref;
  final void Function(int group, String color) onSelect;
  final VoidCallback onRemove;

  const _FavoriteSheet({
    required this.currentPref,
    required this.onSelect,
    required this.onRemove,
  });

  static const _groups = [
    (group: 1, color: 'red', value: 0xFFE53935, label: 'Rojo'),
    (group: 2, color: 'orange', value: 0xFFFF6F00, label: 'Naranja'),
    (group: 3, color: 'yellow', value: 0xFFFFD600, label: 'Amarillo'),
    (group: 4, color: 'green', value: 0xFF43A047, label: 'Verde'),
    (group: 5, color: 'blue', value: 0xFF1E88E5, label: 'Azul'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const SizedBox(height: 20),
            const Text(
              'Añadir a favoritos',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige un grupo de color para organizar tus favoritos.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Color circles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _groups.map((g) {
                final isSelected =
                    currentPref.isFavorite && currentPref.favoriteGroup == g.group;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(g.group, g.color);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(g.value),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(g.value).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 22)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        g.label,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (currentPref.isFavorite) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRemove();
                },
                icon: const Icon(Icons.favorite_border,
                    size: 18, color: Colors.white38),
                label: const Text('Quitar de favoritos',
                    style: TextStyle(color: Colors.white38)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool primary;

  const _MuscleChip({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primary
            ? const Color(0xFFE53935).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: primary
            ? Border.all(
                color: const Color(0xFFE53935).withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? const Color(0xFFE53935) : Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RpeRow extends StatelessWidget {
  final String level;
  final int rpe;
  final bool last;

  const _RpeRow({required this.level, required this.rpe, required this.last});

  String get _levelLabel {
    switch (level) {
      case 'principiante':
        return 'Principiante';
      case 'intermedio':
        return 'Intermedio';
      case 'avanzado':
        return 'Avanzado';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_levelLabel,
                style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            'RPE $rpe',
            style: const TextStyle(
                color: Color(0xFFE53935), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
      ],
    );
  }
}
