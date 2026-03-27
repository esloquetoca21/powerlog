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

  static const Map<ExerciseCategory, List<String>> exercises = {
    ExerciseCategory.squat: [
      // Sentadilla competición y variantes principales
      'Sentadilla',
      'Sentadilla con pausa',
      'Sentadilla con pausa en el fondo',
      'Sentadilla con pausa en el paralelo',
      'Sentadilla frontal',
      'Sentadilla frontal con pausa',
      'Sentadilla zombie (brazos al frente)',
      // Variantes de potencia
      'Box Squat',
      'Box Squat con bandas',
      'Sentadilla con cadenas',
      'Sentadilla con bandas',
      'Sentadilla pin (desde el rack)',
      'Sentadilla hasta paralelo',
      'Sentadilla media (half squat)',
      // Variantes de postura
      'Sentadilla búlgara',
      'Sentadilla búlgara con mancuernas',
      'Sentadilla sumo (stance ancho)',
      'Sentadilla goblet',
      'Sentadilla Hack',
      'Sentadilla con talones elevados',
      'Sentadilla con puntas elevadas',
      // Máquinas y accesorio de pierna
      'Prensa de pierna',
      'Prensa de pierna (un solo pie)',
      'Prensa de pierna (pies juntos)',
      'Sentadilla en Smith',
      'Sentadilla en Smith frontal',
      'Hack Squat (máquina)',
      'Extensión de cuádriceps',
      'Extensión de cuádriceps unilateral',
      'Leg Press 45°',
      // Peso corporal / estabilidad
      'Sentadilla con salto',
      'Pistol Squat',
      'Step-up con barra',
      'Step-up con mancuernas',
      'Zancada con barra',
      'Zancada con mancuernas',
      'Zancada caminando',
      'Zancada inversa',
      'Zancada lateral',
    ],
    ExerciseCategory.bench: [
      // Press banca competición y variantes principales
      'Press de banca',
      'Press de banca con pausa',
      'Press de banca con pausa larga',
      'Press de banca agarre cerrado',
      'Press de banca agarre cerrado con pausa',
      'Press de banca agarre ancho',
      'Press de banca con bandas',
      'Press de banca con cadenas',
      // Variantes de inclinación
      'Press inclinado con barra',
      'Press inclinado con mancuernas',
      'Press declinado con barra',
      'Press declinado con mancuernas',
      // Mancuernas y pesas rusas
      'Press con mancuernas (plano)',
      'Press con mancuernas (neutro)',
      'Press con kettlebell',
      // Accesorios de pecho
      'Apertura con mancuernas (plano)',
      'Apertura con mancuernas (inclinado)',
      'Apertura en polea (crossover)',
      'Apertura en máquina',
      'Aperturas con bandas',
      // Tríceps directo (apoyo banca)
      'Fondos',
      'Fondos con lastre',
      'Fondos en paralelas',
      'Extensión de tríceps tumbado (Skullcrusher)',
      'Extensión de tríceps con EZ',
      'Extensión de tríceps en polea alta',
      'Extensión de tríceps en polea baja',
      'Extensión de tríceps por encima de la cabeza',
      'Press francés con mancuernas',
      'Patada de tríceps con mancuernas',
      'Patada de tríceps en polea',
      'Tríceps en banco (dips de banco)',
      // Press militar (hombro, apoyo banca)
      'Press militar con barra',
      'Press militar con mancuernas',
      'Press Arnold',
      'Press de hombro en máquina',
      'Press trasnuca',
    ],
    ExerciseCategory.deadlift: [
      // Peso muerto competición y variantes principales
      'Peso muerto',
      'Peso muerto con pausa',
      'Peso muerto con pausa en rodillas',
      'Peso muerto con pausa por encima de rodillas',
      'Peso muerto sumo',
      'Peso muerto sumo con pausa',
      'Peso muerto sumo déficit',
      'Peso muerto desde el pin (rack pull)',
      'Peso muerto déficit',
      'Peso muerto con bandas',
      'Peso muerto con cadenas',
      // Variantes de cadera y femoral
      'Peso muerto rumano',
      'Peso muerto rumano con mancuernas',
      'Peso muerto rumano unilateral',
      'Peso muerto stiff leg',
      'Peso muerto en valija (suitcase)',
      // Hip thrust y glúteos
      'Hip thrust con barra',
      'Hip thrust con mancuerna',
      'Hip thrust en máquina',
      'Hip thrust unilateral',
      'Patada de glúteo en polea',
      'Patada de glúteo en cuadrupedia',
      'Puente de glúteo',
      'Puente de glúteo unilateral',
      // Isquiotibiales
      'Good morning con barra',
      'Good morning sentado',
      'Curl de femoral tumbado',
      'Curl de femoral sentado',
      'Curl de femoral de pie (máquina)',
      'Curl nórdico',
      'Curl de femoral con pelota suiza',
      // Espalda baja y core
      'Hiperextensión (espalda baja)',
      'Hiperextensión inversa',
      'Hiperextensión 45°',
      'Superman',
      'Pallof press',
    ],
    ExerciseCategory.accessory: [
      // Espalda (tracción vertical)
      'Dominadas',
      'Dominadas con lastre',
      'Dominadas agarre supino (chin-ups)',
      'Jalón al pecho',
      'Jalón al pecho agarre cerrado',
      'Jalón al pecho agarre supino',
      'Jalón al pecho con un brazo',
      'Pullover con mancuerna',
      'Pullover en polea',
      // Espalda (tracción horizontal)
      'Remo con barra',
      'Remo con barra (pronado)',
      'Remo con barra (supino / Yates row)',
      'Remo con mancuerna',
      'Remo en polea baja',
      'Remo en polea alta',
      'Remo en máquina (pecho apoyado)',
      'Remo TRX / anillas',
      'Face pull',
      'Face pull con rotación externa',
      // Hombros (aislamiento)
      'Elevación lateral con mancuernas',
      'Elevación lateral en polea',
      'Elevación frontal con mancuernas',
      'Elevación frontal con barra',
      'Pájaro (elevación posterior)',
      'Pájaro en polea',
      // Bíceps
      'Curl de bíceps con barra',
      'Curl de bíceps con mancuernas',
      'Curl martillo',
      'Curl martillo con cuerda',
      'Curl predicador (Scott)',
      'Curl concentrado',
      'Curl en polea baja',
      'Curl araña',
      // Trapecios y cuello
      'Encogimientos con barra',
      'Encogimientos con mancuernas',
      'Encogimientos en máquina',
      // Core y abdomen
      'Plancha',
      'Plancha lateral',
      'Plancha con desplazamiento',
      'Rueda abdominal',
      'Crunch',
      'Crunch en polea',
      'Elevación de piernas tumbado',
      'Elevación de piernas en barra',
      'Dragon flag',
      'Tijeras',
      'Rotación rusa',
      // Pantorrillas
      'Gemelos de pie',
      'Gemelos sentado',
      'Gemelos en prensa',
      // Cardio / Potencia
      'Remo ergómetro',
      'Assault bike',
      'Salto a cajón (box jump)',
      'Salto con cuerda',
      'Swing con kettlebell',
      'Turkish get-up',
      'Clean con barra',
      'Push press con barra',
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredExercises {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      return exercises[_selectedCategory] ?? [];
    }
    // Con texto: busca en todas las categorías
    return exercises.values
        .expand((list) => list)
        .where((e) => e.toLowerCase().contains(query))
        .toList();
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
