import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_def_model.dart';
import '../../models/exercise_model.dart';
import '../../services/exercise_service.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

// ---------------------------------------------------------------------------
// ExerciseLibraryScreen
// ---------------------------------------------------------------------------

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  ExerciseCategory? _selectedCategory;
  String? _selectedMuscle;
  String? _selectedEquipment;
  int? _selectedDifficulty;
  bool _favoritesOnly = false;
  bool _showHidden = false;
  bool _gridView = false;
  String _sortOrder = 'az';

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _categoryColor(ExerciseCategory cat) {
    switch (cat) {
      case ExerciseCategory.squat:
        return const Color(0xFFFF6F00);
      case ExerciseCategory.bench:
        return const Color(0xFF1E88E5);
      case ExerciseCategory.deadlift:
        return const Color(0xFFE53935);
      case ExerciseCategory.row:
        return const Color(0xFF43A047);
      case ExerciseCategory.overhead:
        return const Color(0xFF8E24AA);
      case ExerciseCategory.olympic:
        return const Color(0xFFFFD600);
      case ExerciseCategory.carry:
        return const Color(0xFF00ACC1);
      case ExerciseCategory.accessory:
        return const Color(0xFF757575);
    }
  }

  List<ExerciseDef> _getFilteredExercises(ExerciseService svc) {
    var list = svc.search(
      _query,
      category: _selectedCategory,
      primaryMuscle: _selectedMuscle,
      equipment: _selectedEquipment,
      difficulty: _selectedDifficulty,
      favoritesOnly: _favoritesOnly,
      showHidden: _showHidden,
    );

    switch (_sortOrder) {
      case 'difficulty':
        list = [...list]..sort((a, b) => a.difficulty.compareTo(b.difficulty));
        break;
      case 'az':
      default:
        list = [...list]..sort((a, b) => a.name.compareTo(b.name));
    }

    return list;
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedMuscle != null ||
      _selectedEquipment != null ||
      _selectedDifficulty != null ||
      _favoritesOnly ||
      _showHidden;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedMuscle = null;
      _selectedEquipment = null;
      _selectedDifficulty = null;
      _favoritesOnly = false;
      _showHidden = false;
    });
  }

  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Ordenar por',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortRadioTile(ctx, 'az', 'A-Z'),
            _sortRadioTile(ctx, 'recent', 'Más usados'),
            _sortRadioTile(ctx, 'difficulty', 'Dificultad'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortRadioTile(BuildContext ctx, String value, String label) {
    final selected = _sortOrder == value;
    return InkWell(
      onTap: () {
        setState(() => _sortOrder = value);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFE53935)
                      : Colors.white38,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        selectedMuscle: _selectedMuscle,
        selectedEquipment: _selectedEquipment,
        onMuscleSelected: (m) => setState(() => _selectedMuscle = m),
        onEquipmentSelected: (e) => setState(() => _selectedEquipment = e),
        onClear: _clearFilters,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ExerciseService>();
    if (svc.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE53935)),
        ),
      );
    }
    final exercises = _getFilteredExercises(svc);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text(
          'Biblioteca de ejercicios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _gridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
            tooltip: _gridView ? 'Vista lista' : 'Vista cuadrícula',
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune, color: Colors.white),
                if (_hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filtros',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Ordenar',
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withValues(alpha: 0.4), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE53935), width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Horizontal filter chips ───────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Category chips
                ..._categoryChips(),
                const SizedBox(width: 6),
                // Difficulty chips
                ..._difficultyChips(),
                const SizedBox(width: 6),
                // Favorites
                _FilterChipWidget(
                  label: 'Solo favoritos',
                  icon: Icons.favorite,
                  selected: _favoritesOnly,
                  onTap: () =>
                      setState(() => _favoritesOnly = !_favoritesOnly),
                ),
                const SizedBox(width: 6),
                // Show hidden
                _FilterChipWidget(
                  label: 'Mostrar ocultos',
                  icon: Icons.visibility,
                  selected: _showHidden,
                  onTap: () => setState(() => _showHidden = !_showHidden),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Active filter summary ─────────────────────────────────────
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${exercises.length} resultado${exercises.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: const Text(
                      'Limpiar filtros',
                      style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: exercises.isEmpty
                ? _EmptyState(hasFilters: _hasActiveFilters || _query.isNotEmpty)
                : _gridView
                    ? _GridBody(
                        exercises: exercises,
                        categoryColor: _categoryColor,
                      )
                    : _ListBody(
                        exercises: exercises,
                        categoryColor: _categoryColor,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        tooltip: 'Nuevo ejercicio',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CreateExerciseScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────

  List<Widget> _categoryChips() {
    const categories = [
      (ExerciseCategory.squat, 'Sentadilla'),
      (ExerciseCategory.bench, 'Banca'),
      (ExerciseCategory.deadlift, 'Peso muerto'),
      (ExerciseCategory.row, 'Remo'),
      (ExerciseCategory.overhead, 'Press OHP'),
      (ExerciseCategory.olympic, 'Olímpico'),
      (ExerciseCategory.carry, 'Acarreo'),
      (ExerciseCategory.accessory, 'Accesorio'),
    ];

    return categories.map((entry) {
      final (cat, label) = entry;
      final selected = _selectedCategory == cat;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: _FilterChipWidget(
          label: label,
          selected: selected,
          accentColor: selected ? _categoryColor(cat) : null,
          onTap: () => setState(() {
            _selectedCategory = selected ? null : cat;
          }),
        ),
      );
    }).toList();
  }

  // ── Difficulty chips ───────────────────────────────────────────────────────

  List<Widget> _difficultyChips() {
    const difficulties = [
      (1, '⭐ Principiante'),
      (2, '⭐⭐ Básico'),
      (3, '⭐⭐⭐ Intermedio'),
      (4, '⭐⭐⭐⭐ Avanzado'),
      (5, '⭐⭐⭐⭐⭐ Elite'),
    ];

    return difficulties.map((entry) {
      final (level, label) = entry;
      final selected = _selectedDifficulty == level;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: _FilterChipWidget(
          label: label,
          selected: selected,
          onTap: () => setState(() {
            _selectedDifficulty = selected ? null : level;
          }),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Filter chip widget
// ---------------------------------------------------------------------------

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? const Color(0xFFE53935);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? accent.withValues(alpha: 0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? accent : Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color:
                    selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List body
// ---------------------------------------------------------------------------

class _ListBody extends StatelessWidget {
  final List<ExerciseDef> exercises;
  final Color Function(ExerciseCategory) categoryColor;

  const _ListBody({
    required this.exercises,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: exercises.length,
      itemBuilder: (ctx, i) => _ExerciseListTile(
        exercise: exercises[i],
        categoryColor: categoryColor(exercises[i].category),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid body
// ---------------------------------------------------------------------------

class _GridBody extends StatelessWidget {
  final List<ExerciseDef> exercises;
  final Color Function(ExerciseCategory) categoryColor;

  const _GridBody({
    required this.exercises,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: exercises.length,
      itemBuilder: (ctx, i) => _ExerciseGridCard(
        exercise: exercises[i],
        categoryColor: categoryColor(exercises[i].category),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise list tile
// ---------------------------------------------------------------------------

class _ExerciseListTile extends StatelessWidget {
  final ExerciseDef exercise;
  final Color categoryColor;

  const _ExerciseListTile({
    required this.exercise,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exerciseDef: exercise),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // Leading circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: categoryColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Center(
                child: Text(
                  exercise.name[0].toUpperCase(),
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${exercise.primaryMuscle} · ${exercise.categoryLabel}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            // Trailing
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (exercise.isCustom)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              const Color(0xFFE53935).withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Personalizado',
                      style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                Icon(
                  Icons.favorite_border,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise grid card
// ---------------------------------------------------------------------------

class _ExerciseGridCard extends StatelessWidget {
  final ExerciseDef exercise;
  final Color categoryColor;

  const _ExerciseGridCard({
    required this.exercise,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exerciseDef: exercise),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.primaryMuscle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exercise.categoryLabel,
                        style: TextStyle(
                            color: categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.fitness_center,
              color: Colors.white.withValues(alpha: 0.15),
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Sin resultados'
                  : 'No hay ejercicios todavía',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Prueba con otros filtros o términos de búsqueda.'
                  : 'Pulsa el botón + para crear tu primer ejercicio personalizado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

class _FilterSheet extends StatelessWidget {
  final String? selectedMuscle;
  final String? selectedEquipment;
  final ValueChanged<String?> onMuscleSelected;
  final ValueChanged<String?> onEquipmentSelected;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.selectedMuscle,
    required this.selectedEquipment,
    required this.onMuscleSelected,
    required this.onEquipmentSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        onClear();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A)),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Muscle filter
                    const _SheetSectionLabel('Músculo'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kAllMuscles.map((m) {
                        final selected = selectedMuscle == m;
                        return _SheetChip(
                          label: m,
                          selected: selected,
                          onTap: () =>
                              onMuscleSelected(selected ? null : m),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Equipment filter
                    const _SheetSectionLabel('Equipamiento'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kAllEquipment.map((e) {
                        final selected = selectedEquipment == e;
                        return _SheetChip(
                          label: e,
                          selected: selected,
                          onTap: () =>
                              onEquipmentSelected(selected ? null : e),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Aplicar filtros',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE53935).withValues(alpha: 0.15)
              : const Color(0xFF242424),
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
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
