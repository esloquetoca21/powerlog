import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_model.dart';
import '../models/set_model.dart';
import '../services/session_service.dart';

class AddExerciseSheet extends StatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  static const _uuid = Uuid();
  final _searchController = TextEditingController();
  ExerciseCategory _selectedCategory = ExerciseCategory.squat;

  static const Map<ExerciseCategory, List<String>> _exercises = {
    ExerciseCategory.squat: [
      'Sentadilla',
      'Sentadilla con pausa',
      'Sentadilla frontal',
      'Box Squat',
      'Sentadilla búlgara',
      'Prensa de pierna',
    ],
    ExerciseCategory.bench: [
      'Press de banca',
      'Press de banca con pausa',
      'Press de banca agarre cerrado',
      'Press inclinado',
      'Press con mancuernas',
      'Fondos',
    ],
    ExerciseCategory.deadlift: [
      'Peso muerto',
      'Peso muerto rumano',
      'Peso muerto sumo',
      'Peso muerto con pausa',
      'Good morning',
      'Hip thrust',
    ],
    ExerciseCategory.accessory: [
      'Remo con barra',
      'Dominadas',
      'Curl de bíceps',
      'Extensión de tríceps',
      'Face pull',
      'Jalón al pecho',
      'Curl de femoral',
      'Extensión de cuádriceps',
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredExercises {
    final query = _searchController.text.toLowerCase();
    final base = _exercises[_selectedCategory] ?? [];
    if (query.isEmpty) return base;
    return base.where((e) => e.toLowerCase().contains(query)).toList();
  }

  void _selectExercise(String name) {
    final exercise = ExerciseModel(
      id: _uuid.v4(),
      name: name,
      category: _selectedCategory,
      sets: [SetModel(id: _uuid.v4(), setNumber: 1, weight: 0, reps: 5, timestamp: DateTime.now())],
    );
    context.read<SessionService>().addExercise(exercise);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Añadir ejercicio',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
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
            // Category tabs
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ExerciseCategory.values.map((cat) {
                  final selected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_categoryLabel(cat)),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      selectedColor: const Color(0xFFE53935),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 13),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Exercise list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final name = _filteredExercises[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: const Icon(Icons.fitness_center,
                        color: Color(0xFFE53935), size: 20),
                    title: Text(name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15)),
                    onTap: () => _selectExercise(name),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _categoryLabel(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.squat:
        return 'Sentadilla';
      case ExerciseCategory.bench:
        return 'Banca';
      case ExerciseCategory.deadlift:
        return 'Peso Muerto';
      case ExerciseCategory.accessory:
        return 'Accesorio';
    }
  }
}
