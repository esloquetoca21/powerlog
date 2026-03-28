import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/exercise_def_model.dart';
import '../../models/exercise_pref_model.dart';
import '../../models/session_model.dart';
import '../../services/auth_service.dart';
import '../../services/exercise_service.dart';
import '../../services/exercise_stats_service.dart';
import '../../services/session_service.dart';
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
      final svc = context.read<ExerciseService>();
      if (uid != null) {
        await svc.saveCustomExercise(result, uid);
      }
      if (mounted) Navigator.of(context).pop();
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
            _StatsTab(def: def),
            _NotesTab(pref: _pref, def: def, onPrefUpdated: (p) {
              if (mounted) setState(() => _pref = p);
            }),
            _VideoTab(def: def, pref: _pref, onPrefUpdated: (p) {
              if (mounted) setState(() => _pref = p);
            }),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: Color(0xFFE74C3C), label: 'Primario'),
            SizedBox(width: 16),
            _Legend(color: Color(0xFFE67E22), label: 'Secundario'),
          ],
        ),

        const SizedBox(height: 24),

        // Description
        if (def.description != null && def.description!.isNotEmpty) ...[
          const _SectionHeader('Descripción'),
          const SizedBox(height: 8),
          Text(
            def.description!,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), height: 1.5),
          ),
          const SizedBox(height: 24),
        ],

        // Muscle chips
        const _SectionHeader('Músculos'),
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
          const _SectionHeader('Equipamiento'),
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
          const _SectionHeader('Disciplinas'),
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
          const _SectionHeader('Ejecución'),
          const SizedBox(height: 10),
          for (int i = 0; i < def.instructions.length; i++)
            _InstructionRow(number: i + 1, text: def.instructions[i]),
          const SizedBox(height: 20),
        ],

        // Cues
        if (def.cues.isNotEmpty) ...[
          const _SectionHeader('Cues técnicos'),
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
          const _SectionHeader('RPE recomendado'),
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
          const _SectionHeader('Etiquetas'),
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

// ── Tab Estadísticas ─────────────────────────────────────────────────────────

class _StatsTab extends StatefulWidget {
  final ExerciseDef def;

  const _StatsTab({required this.def});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  String _period = 'todo';
  late Future<ExerciseStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<ExerciseStats> _loadStats() async {
    final sessions = context.read<SessionService>().sessions;
    final svc = ExerciseStatsService();
    // Two-pass: first to get maxEstimated1RM for RPE % calculation
    final first = svc.calculate(widget.def.name, sessions, 0);
    if (first.totalSets == 0) return first;
    return svc.calculate(widget.def.name, sessions, first.maxEstimated1RM);
  }

  List<({DateTime date, double value})> _filtered(
      List<({DateTime date, double value})> history) {
    if (_period == 'todo' || history.isEmpty) return history;
    final now = DateTime.now();
    final cutoff = switch (_period) {
      '1M' => now.subtract(const Duration(days: 30)),
      '3M' => now.subtract(const Duration(days: 90)),
      '6M' => now.subtract(const Duration(days: 180)),
      '1A' => now.subtract(const Duration(days: 365)),
      _ => DateTime(2000),
    };
    return history.where((p) => p.date.isAfter(cutoff)).toList();
  }

  String _fmtDate(DateTime d) {
    const m = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  String _fmtVolume(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} Mt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} t';
    return '$v kg';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExerciseStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
                color: Color(0xFFE53935), strokeWidth: 2),
          );
        }

        final stats = snapshot.data!;

        if (stats.totalSets == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_outlined,
                    size: 52, color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: 16),
                const Text('Sin datos todavía',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Empieza a registrar este ejercicio para ver tus estadísticas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }

        final filteredHistory = _filtered(stats.estimated1rmHistory);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Records ───────────────────────────────────────────────────
              const _StatsSectionHeader('Récords personales'),
              const SizedBox(height: 12),
              // 1RM estimado (featured)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        color: Color(0xFFE53935), size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats.maxEstimated1RM.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('1RM estimado máximo (Epley)',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 12)),
                      ],
                    ),
                    if (stats.prDate != null) ...[
                      const Spacer(),
                      Text(
                        _fmtDate(stats.prDate!),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // PR, max reps, volume row
              Row(
                children: [
                  _StatMiniCard(
                    label: 'Récord personal',
                    value: stats.personalRecord != null
                        ? '${stats.personalRecord!.weight.toStringAsFixed(1)} kg'
                        : '—',
                    sub: stats.personalRecord != null
                        ? '× ${stats.personalRecord!.reps} reps'
                        : '',
                  ),
                  const SizedBox(width: 8),
                  _StatMiniCard(
                    label: 'Máx. reps',
                    value: stats.allSets.isEmpty
                        ? '—'
                        : () {
                            final maxRep = stats.allSets
                                .reduce((a, b) => a.reps > b.reps ? a : b);
                            return '${maxRep.reps} reps';
                          }(),
                    sub: stats.allSets.isEmpty
                        ? ''
                        : () {
                            final maxRep = stats.allSets
                                .reduce((a, b) => a.reps > b.reps ? a : b);
                            return '${maxRep.weight.toStringAsFixed(1)} kg';
                          }(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatMiniCard(
                    label: 'Volumen total',
                    value: _fmtVolume(stats.totalVolume),
                    sub: '${stats.totalSets} series',
                  ),
                  const SizedBox(width: 8),
                  _StatMiniCard(
                    label: 'Última vez',
                    value: stats.lastPerformed != null
                        ? _fmtDate(stats.lastPerformed!)
                        : '—',
                    sub: '',
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Strength curve ────────────────────────────────────────────
              const _StatsSectionHeader('Curva fuerza-resistencia'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Repeticiones',
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12)),
                          ),
                          Text('Mejor peso',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ...() {
                      const repLabels = [
                        (reps: 1, label: '1RM est.'),
                        (reps: 2, label: '2RM'),
                        (reps: 3, label: '3RM'),
                        (reps: 5, label: '5RM'),
                        (reps: 8, label: '8RM'),
                        (reps: 10, label: '10RM'),
                        (reps: 15, label: '15RM'),
                        (reps: 20, label: '20RM'),
                      ];
                      return repLabels.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final weight = item.reps == 1
                            ? (stats.maxEstimated1RM > 0
                                ? stats.maxEstimated1RM
                                : null)
                            : stats.strengthCurve[item.reps];
                        final last = i == repLabels.length - 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          decoration: BoxDecoration(
                            border: last
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                        color: Colors.white10)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item.label,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14)),
                              ),
                              Text(
                                weight != null
                                    ? '${weight.toStringAsFixed(1)} kg'
                                    : '—',
                                style: TextStyle(
                                  color: weight != null
                                      ? const Color(0xFFE53935)
                                      : Colors.white.withValues(alpha: 0.25),
                                  fontWeight: weight != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    }(),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 1RM progress chart ────────────────────────────────────────
              const _StatsSectionHeader('Progreso 1RM estimado'),
              const SizedBox(height: 12),
              // Period selector
              Row(
                children: ['1M', '3M', '6M', '1A', 'Todo'].map((p) {
                  final sel = p == _period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFFE53935)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p,
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (filteredHistory.length < 2)
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No hay suficientes datos para este período.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13),
                  ),
                )
              else
                _Stats1rmChart(history: filteredHistory),

              const SizedBox(height: 28),

              // ── Best session ──────────────────────────────────────────────
              if (stats.bestVolumeSession != null) ...[
                const _StatsSectionHeader('Mejor sesión histórica'),
                const SizedBox(height: 12),
                _BestSessionCard(
                  session: stats.bestVolumeSession!,
                  exerciseName: widget.def.name,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Stats helpers ─────────────────────────────────────────────────────────────

class _StatsSectionHeader extends StatelessWidget {
  final String text;

  const _StatsSectionHeader(this.text);

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

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.sub,
  });

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
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            if (sub.isNotEmpty)
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── 1RM line chart ────────────────────────────────────────────────────────────

class _Stats1rmChart extends StatelessWidget {
  final List<({DateTime date, double value})> history;

  const _Stats1rmChart({required this.history});

  @override
  Widget build(BuildContext context) {
    // Compute which entries are PRs (running maximum)
    final prFlags = <bool>[];
    double runMax = 0;
    for (final h in history) {
      if (h.value > runMax) {
        runMax = h.value;
        prFlags.add(true);
      } else {
        prFlags.add(false);
      }
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: CustomPaint(
        painter: _Stats1rmPainter(history: history, prFlags: prFlags),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Stats1rmPainter extends CustomPainter {
  final List<({DateTime date, double value})> history;
  final List<bool> prFlags;

  _Stats1rmPainter({required this.history, required this.prFlags});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    const padLeft = 44.0;
    const padBottom = 28.0;
    const padTop = 8.0;
    const padRight = 8.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    final minV =
        history.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxV =
        history.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final rangeV = (maxV - minV).clamp(1.0, double.infinity);

    final minT =
        history.first.date.millisecondsSinceEpoch.toDouble();
    final maxT =
        history.last.date.millisecondsSinceEpoch.toDouble();
    final rangeT = (maxT - minT).clamp(1.0, double.infinity);

    Offset toCanvas(({DateTime date, double value}) p) {
      final x =
          padLeft + (p.date.millisecondsSinceEpoch - minT) / rangeT * chartW;
      final y = padTop + (1 - (p.value - minV) / rangeV) * chartH;
      return Offset(x, y);
    }

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = padTop + chartH * i / 3;
      canvas.drawLine(
          Offset(padLeft, y), Offset(padLeft + chartW, y), gridPaint);
    }

    // Y labels
    final labelStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.35), fontSize: 10);
    for (int i = 0; i <= 3; i++) {
      final val = maxV - (rangeV * i / 3);
      final y = padTop + chartH * i / 3;
      _drawText(canvas, val.toStringAsFixed(0), Offset(0, y - 6), 42,
          labelStyle, TextAlign.right);
    }

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(padLeft, padTop + chartH);
    for (final p in history) {
      fillPath.lineTo(toCanvas(p).dx, toCanvas(p).dy);
    }
    fillPath.lineTo(toCanvas(history.last).dx, padTop + chartH);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE53935).withValues(alpha: 0.18),
            const Color(0xFFE53935).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(padLeft, padTop, chartW, chartH)),
    );

    // Line
    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final pt = toCanvas(history[i]);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots — gold for PRs, red for regular
    final dotBg = Paint()..color = const Color(0xFF1A1A1A);
    for (int i = 0; i < history.length; i++) {
      final pt = toCanvas(history[i]);
      final isPr = prFlags[i];
      final dotColor =
          isPr ? const Color(0xFFFFD600) : const Color(0xFFE53935);
      canvas.drawCircle(pt, 5, dotBg);
      canvas.drawCircle(pt, isPr ? 4 : 3, Paint()..color = dotColor);
    }

    // X axis labels (first and last)
    _drawText(
      canvas,
      _shortDate(history.first.date),
      Offset(padLeft, size.height - padBottom + 6),
      50,
      labelStyle,
      TextAlign.left,
    );
    _drawText(
      canvas,
      _shortDate(history.last.date),
      Offset(size.width - padRight - 46, size.height - padBottom + 6),
      50,
      labelStyle,
      TextAlign.right,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, double width,
      TextStyle style, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    tp.paint(canvas, offset);
  }

  String _shortDate(DateTime d) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month]}';
  }

  @override
  bool shouldRepaint(_Stats1rmPainter old) =>
      old.history != history || old.prFlags != prFlags;
}

// ── Best session card ─────────────────────────────────────────────────────────

class _BestSessionCard extends StatefulWidget {
  final SessionModel session;
  final String exerciseName;

  const _BestSessionCard({
    required this.session,
    required this.exerciseName,
  });

  @override
  State<_BestSessionCard> createState() => _BestSessionCardState();
}

class _BestSessionCardState extends State<_BestSessionCard> {
  bool _expanded = false;

  String _fmtDate(DateTime d) {
    const m = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${m[d.month]} ${d.year}';
  }

  String _fmtVolume(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} t';
    return '$v kg';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final exercise = session.exercises.firstWhere(
      (e) => e.name.toLowerCase() == widget.exerciseName.toLowerCase(),
      orElse: () => session.exercises.first,
    );
    final volume =
        exercise.sets.fold<int>(0, (s, e) => s + (e.weight * e.reps).round());

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined,
                      color: Color(0xFFE53935), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '${_fmtDate(session.date)}  ·  ${_fmtVolume(volume)} de volumen',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
            // Expanded series list
            if (_expanded) ...[
              const Divider(height: 1, color: Colors.white10),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: exercise.sets.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFE53935).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Color(0xFFE53935),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${s.weight.toStringAsFixed(1)} kg × ${s.reps} reps',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          if (s.rpe != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'RPE ${s.rpe!.toStringAsFixed(1)}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab Vídeo ─────────────────────────────────────────────────────────────────

class _VideoTab extends StatefulWidget {
  final ExerciseDef def;
  final ExercisePref pref;
  final ValueChanged<ExercisePref> onPrefUpdated;

  const _VideoTab({
    required this.def,
    required this.pref,
    required this.onPrefUpdated,
  });

  @override
  State<_VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<_VideoTab> {
  late ExercisePref _pref;

  @override
  void initState() {
    super.initState();
    _pref = widget.pref;
  }

  @override
  void didUpdateWidget(_VideoTab old) {
    super.didUpdateWidget(old);
    if (old.pref != widget.pref) _pref = widget.pref;
  }

  String? get _effectiveUrl =>
      _pref.customVideoUrl?.isNotEmpty == true
          ? _pref.customVideoUrl
          : (widget.def.videoUrl?.isNotEmpty == true
              ? widget.def.videoUrl
              : null);

  String? get _videoId {
    final url = _effectiveUrl;
    if (url == null) return null;
    return YoutubePlayer.convertUrlToId(url);
  }

  Future<void> _openUrlDialog({bool editing = false}) async {
    final ctrl = TextEditingController(
        text: editing ? (_pref.customVideoUrl ?? '') : '');
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            editing ? 'Cambiar vídeo' : 'Añadir vídeo de referencia',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pega una URL de YouTube',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorText: errorText,
                  errorStyle: const TextStyle(color: Color(0xFFE53935)),
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              if (editing && _pref.customVideoUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _removeCustomVideo();
                  },
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.white38),
                  label: const Text('Eliminar vídeo personalizado',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                final url = ctrl.text.trim();
                if (url.isEmpty) {
                  setDialogState(
                      () => errorText = 'Introduce una URL.');
                  return;
                }
                final isYoutube = url.contains('youtube.com') ||
                    url.contains('youtu.be');
                if (!isYoutube) {
                  setDialogState(() =>
                      errorText = 'La URL debe ser de YouTube.');
                  return;
                }
                final id = YoutubePlayer.convertUrlToId(url);
                if (id == null) {
                  setDialogState(() =>
                      errorText = 'No se reconoce como vídeo de YouTube.');
                  return;
                }
                Navigator.pop(ctx);
                await _saveCustomVideo(url);
              },
              child: const Text('Guardar',
                  style: TextStyle(color: Color(0xFFE53935))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomVideo(String url) async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    final updated = _pref.copyWith(
      customVideoUrl: url,
      updatedAt: DateTime.now(),
    );
    await context.read<ExerciseService>().updatePref(updated, uid);
    if (mounted) {
      setState(() => _pref = updated);
      widget.onPrefUpdated(updated);
    }
  }

  Future<void> _removeCustomVideo() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    final updated = _pref.copyWith(
      clearCustomVideoUrl: true,
      updatedAt: DateTime.now(),
    );
    await context.read<ExerciseService>().updatePref(updated, uid);
    if (mounted) {
      setState(() => _pref = updated);
      widget.onPrefUpdated(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId;
    final hasCustom = _pref.customVideoUrl?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (videoId != null) ...[
            // Thumbnail + player
            _VideoThumbnail(
              videoId: videoId,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _YoutubePlayerScreen(videoId: videoId),
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (hasCustom)
              Text(
                'Vídeo personalizado',
                style: TextStyle(
                    color: const Color(0xFFE53935).withValues(alpha: 0.8),
                    fontSize: 11),
              )
            else
              Text(
                'Vídeo del sistema',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11),
              ),
            const SizedBox(height: 20),
            // Action buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openUrlDialog(editing: true),
                icon: const Icon(Icons.video_library_outlined,
                    size: 18, color: Color(0xFFE53935)),
                label: Text(
                  hasCustom ? 'Cambiar vídeo' : 'Usar mi propio vídeo',
                  style: const TextStyle(color: Color(0xFFE53935)),
                ),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: Color(0xFFE53935), width: 1),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (hasCustom) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _removeCustomVideo,
                  icon: Icon(Icons.delete_outline,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.35)),
                  label: Text(
                    'Eliminar vídeo personalizado',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Empty state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.12)),
                    const SizedBox(height: 16),
                    const Text('Sin vídeo de referencia',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Añade un vídeo de YouTube\npara tener una referencia técnica.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openUrlDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Añadir vídeo de referencia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Video thumbnail widget ────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  final String videoId;
  final VoidCallback onTap;

  const _VideoThumbnail({required this.videoId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbUrl =
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white24, size: 40),
                  ),
                ),
              ),
              // Dark overlay
              Container(color: Colors.black.withValues(alpha: 0.35)),
              // Play button
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fullscreen YouTube player screen ─────────────────────────────────────────

class _YoutubePlayerScreen extends StatefulWidget {
  final String videoId;

  const _YoutubePlayerScreen({required this.videoId});

  @override
  State<_YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<_YoutubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE53935),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFE53935),
          handleColor: Color(0xFFE53935),
        ),
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(child: player),
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
