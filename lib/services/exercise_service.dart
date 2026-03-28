import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/exercise_def_model.dart';
import '../models/exercise_model.dart';
import '../models/exercise_pref_model.dart';
import '../models/session_model.dart';

class ExerciseService extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  List<ExerciseDef> _systemExercises = [];
  List<ExerciseDef> _customExercises = [];
  Map<String, ExercisePref> _prefs = {};
  bool _isLoading = false;
  String? _currentUid;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<ExerciseDef> get systemExercises => List.unmodifiable(_systemExercises);
  List<ExerciseDef> get customExercises => List.unmodifiable(_customExercises);

  /// Custom exercises first, then system exercises.
  List<ExerciseDef> get allExercises => [
        ..._customExercises,
        ..._systemExercises,
      ];

  bool get isLoading => _isLoading;

  ExercisePref getPref(String exerciseId) =>
      _prefs[exerciseId] ?? ExercisePref.empty(exerciseId);

  // ── Firestore references ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _customExercisesRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('custom_exercises');

  CollectionReference<Map<String, dynamic>> _prefsRef(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exercise_prefs');

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize(String uid) async {
    if (_currentUid == uid && _systemExercises.isNotEmpty) return;
    _currentUid = uid;
    _isLoading = true;
    notifyListeners();

    try {
      // Load system exercises from Firestore; fall back to seed if empty/fails.
      List<ExerciseDef> systemLoaded = [];
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('exercises').get();
        if (snapshot.docs.isNotEmpty) {
          systemLoaded = snapshot.docs
              .map((doc) => ExerciseDef.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
        }
      } catch (_) {
        // Intentionally ignored — we'll use seed data below.
      }

      _systemExercises =
          systemLoaded.isNotEmpty ? systemLoaded : _buildSeedExercises();

      // Load user's custom exercises.
      final customSnapshot = await _customExercisesRef(uid).get();
      _customExercises = customSnapshot.docs
          .map((doc) => ExerciseDef.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Load preferences.
      await refreshPrefs(uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPrefs(String uid) async {
    final snapshot = await _prefsRef(uid).get();
    _prefs = {
      for (final doc in snapshot.docs)
        doc.id: ExercisePref.fromMap({...doc.data(), 'exerciseId': doc.id})
    };
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> saveCustomExercise(ExerciseDef exercise, String uid) async {
    await _customExercisesRef(uid)
        .doc(exercise.id)
        .set(exercise.toMap()..['timestamp'] = exercise.timestamp);

    final idx = _customExercises.indexWhere((e) => e.id == exercise.id);
    if (idx >= 0) {
      _customExercises[idx] = exercise;
    } else {
      _customExercises = [exercise, ..._customExercises];
    }
    notifyListeners();
  }

  Future<void> deleteCustomExercise(String exerciseId, String uid) async {
    await _customExercisesRef(uid).doc(exerciseId).delete();
    _customExercises = _customExercises.where((e) => e.id != exerciseId).toList();
    notifyListeners();
  }

  Future<void> updatePref(ExercisePref pref, String uid) async {
    await _prefsRef(uid).doc(pref.exerciseId).set(pref.toMap());
    _prefs[pref.exerciseId] = pref;
    notifyListeners();
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  List<ExerciseDef> search(
    String query, {
    ExerciseCategory? category,
    String? primaryMuscle,
    String? equipment,
    String? discipline,
    int? difficulty,
    bool favoritesOnly = false,
    bool showHidden = false,
  }) {
    final q = query.toLowerCase().trim();
    return allExercises.where((ex) {
      // Hidden filter
      if (!showHidden && (_prefs[ex.id]?.isHidden ?? false)) return false;

      // Favorites filter
      if (favoritesOnly && !(_prefs[ex.id]?.isFavorite ?? false)) return false;

      // Text filter
      if (q.isNotEmpty && !ex.name.toLowerCase().contains(q)) return false;

      // Category filter
      if (category != null && ex.category != category) return false;

      // Primary muscle filter
      if (primaryMuscle != null && ex.primaryMuscle != primaryMuscle) {
        return false;
      }

      // Equipment filter
      if (equipment != null && !ex.equipment.contains(equipment)) return false;

      // Discipline filter
      if (discipline != null && !ex.disciplines.contains(discipline)) {
        return false;
      }

      // Difficulty filter
      if (difficulty != null && ex.difficulty != difficulty) return false;

      return true;
    }).toList();
  }

  // ── Recently used ──────────────────────────────────────────────────────────

  List<ExerciseDef> recentlyUsed(List<SessionModel> sessions, {int limit = 8}) {
    // Sort sessions newest first.
    final sorted = [...sessions]..sort((a, b) => b.date.compareTo(a.date));

    final seen = <String>{};
    final result = <ExerciseDef>[];

    for (final session in sorted) {
      for (final exercise in session.exercises) {
        final nameLower = exercise.name.toLowerCase();
        if (!seen.contains(nameLower)) {
          seen.add(nameLower);
          // Find matching ExerciseDef.
          final def = allExercises.firstWhere(
            (d) => d.name.toLowerCase() == nameLower,
            orElse: () => ExerciseDef(
              id: 'recent_${exercise.name}',
              name: exercise.name,
              primaryMuscle: 'varios',
              category: exercise.category,
              timestamp: '2024-01-01T00:00:00.000',
            ),
          );
          result.add(def);
          if (result.length >= limit) return result;
        }
      }
    }
    return result;
  }

  // ── Seed data ──────────────────────────────────────────────────────────────

  static String _makeId(String name) {
    return 'ex_${name.toLowerCase().replaceAll(RegExp(r'[^a-záéíóúñ0-9]'), '_')}';
  }

  static const String _kTimestamp = '2024-01-01T00:00:00.000';

  static int _squatDifficulty(String name) {
    final n = name.toLowerCase();
    if (n.contains('frontal') || n.contains('zombie') || n.contains('pistol')) {
      return 4;
    }
    if (n.contains('con pausa') || n.contains('búlgara') || n.contains('hack squat')) {
      return 3;
    }
    if (n == 'sentadilla' || n.contains('box squat')) return 3;
    return 2;
  }

  static int _benchDifficulty(String name) {
    final n = name.toLowerCase();
    if (n.contains('con pausa')) return 3;
    if (n == 'press de banca') return 2;
    return 2;
  }

  static int _deadliftDifficulty(String name) {
    final n = name.toLowerCase();
    if (n.contains('con pausa') || n.contains('déficit') || n.contains('deficit')) {
      return 4;
    }
    if (n == 'peso muerto' || n == 'peso muerto sumo') return 3;
    return 2;
  }

  static String _accessoryMuscle(String name) {
    final n = name.toLowerCase();
    if (n.contains('dominadas') ||
        n.contains('jalón') ||
        n.contains('jalón') ||
        n.contains('pullover') ||
        (n.contains('remo') && !n.contains('ergómetro'))) {
      return 'dorsales';
    }
    if (n.contains('curl') &&
        !n.contains('nórdico') &&
        !n.contains('femoral')) {
      return 'bíceps';
    }
    if (n.contains('tríceps') ||
        n.contains('tríceps') ||
        n.contains('skullcrusher') ||
        n.contains('press francés') ||
        n.contains('extensión de trí') ||
        n.contains('patada de tríceps')) {
      return 'tríceps';
    }
    if (n.contains('elevación lateral')) return 'deltoides_lateral';
    if (n.contains('elevación frontal')) return 'deltoides_anterior';
    if (n.contains('pájaro') || n.contains('face pull')) {
      return 'deltoides_posterior';
    }
    if (n.contains('curl femoral') || n.contains('nórdico') || n.contains('nordico')) {
      return 'isquiotibiales';
    }
    if (n.contains('extensión de cuád') || n.contains('prensa')) {
      return 'cuádriceps';
    }
    if (n.contains('hip thrust') ||
        n.contains('puente de glúteo') ||
        n.contains('patada de glúteo')) {
      return 'glúteos';
    }
    if (n.contains('plancha') ||
        n.contains('rueda') ||
        n.contains('crunch') ||
        n.contains('rotación rusa') ||
        n.contains('tijeras') ||
        n.contains('pallof')) {
      return 'recto_abdominal';
    }
    if (n.contains('gemelos') || n.contains('sóleo') || n.contains('soleo')) {
      return 'gastrocnemio';
    }
    if (n.contains('encogimientos')) return 'trapecio';
    return 'varios';
  }

  static List<String> _accessorySecondary(String name) {
    final n = name.toLowerCase();
    if (n.contains('dominadas') ||
        n.contains('jalón') ||
        n.contains('pullover') ||
        (n.contains('remo') && !n.contains('ergómetro'))) {
      return ['bíceps'];
    }
    if (n.contains('plancha') ||
        n.contains('rueda') ||
        n.contains('crunch') ||
        n.contains('rotación rusa') ||
        n.contains('tijeras') ||
        n.contains('pallof')) {
      return ['oblicuos', 'core'];
    }
    return [];
  }

  static List<ExerciseDef> _buildSeedExercises() {
    final result = <ExerciseDef>[];

    // ── Squat ──────────────────────────────────────────────────────────────
    const squatNames = [
      'Sentadilla',
      'Sentadilla con pausa',
      'Sentadilla con pausa en el fondo',
      'Sentadilla con pausa en el paralelo',
      'Sentadilla frontal',
      'Sentadilla frontal con pausa',
      'Sentadilla zombie (brazos al frente)',
      'Box Squat',
      'Box Squat con bandas',
      'Sentadilla con cadenas',
      'Sentadilla con bandas',
      'Sentadilla pin (desde el rack)',
      'Sentadilla hasta paralelo',
      'Sentadilla media (half squat)',
      'Sentadilla búlgara',
      'Sentadilla búlgara con mancuernas',
      'Sentadilla sumo (stance ancho)',
      'Sentadilla goblet',
      'Sentadilla Hack',
      'Sentadilla con talones elevados',
      'Sentadilla con puntas elevadas',
      'Prensa de pierna',
      'Prensa de pierna (un solo pie)',
      'Prensa de pierna (pies juntos)',
      'Sentadilla en Smith',
      'Sentadilla en Smith frontal',
      'Hack Squat (máquina)',
      'Extensión de cuádriceps',
      'Extensión de cuádriceps unilateral',
      'Leg Press 45°',
      'Sentadilla con salto',
      'Pistol Squat',
      'Step-up con barra',
      'Step-up con mancuernas',
      'Zancada con barra',
      'Zancada con mancuernas',
      'Zancada caminando',
      'Zancada inversa',
      'Zancada lateral',
    ];

    for (final name in squatNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'cuádriceps',
        secondaryMuscles: const ['glúteos', 'isquiotibiales'],
        category: ExerciseCategory.squat,
        disciplines: const ['powerlifting'],
        equipment: const ['barra'],
        difficulty: _squatDifficulty(name),
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Bench ──────────────────────────────────────────────────────────────
    const benchNames = [
      'Press de banca',
      'Press de banca con pausa',
      'Press de banca con pausa larga',
      'Press de banca agarre cerrado',
      'Press de banca agarre cerrado con pausa',
      'Press de banca agarre ancho',
      'Press de banca con bandas',
      'Press de banca con cadenas',
      'Press inclinado con barra',
      'Press inclinado con mancuernas',
      'Press declinado con barra',
      'Press declinado con mancuernas',
      'Press con mancuernas (plano)',
      'Press con mancuernas (neutro)',
      'Press con kettlebell',
      'Apertura con mancuernas (plano)',
      'Apertura con mancuernas (inclinado)',
      'Apertura en polea (crossover)',
      'Apertura en máquina',
      'Aperturas con bandas',
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
      'Press militar con barra',
      'Press militar con mancuernas',
      'Press Arnold',
      'Press de hombro en máquina',
      'Press trasnuca',
    ];

    for (final name in benchNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'pectoral',
        secondaryMuscles: const ['tríceps', 'deltoides_anterior'],
        category: ExerciseCategory.bench,
        disciplines: const ['powerlifting', 'culturismo'],
        equipment: const ['barra', 'banco'],
        difficulty: _benchDifficulty(name),
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Deadlift ───────────────────────────────────────────────────────────
    const deadliftNames = [
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
      'Peso muerto rumano',
      'Peso muerto rumano con mancuernas',
      'Peso muerto rumano unilateral',
      'Peso muerto stiff leg',
      'Peso muerto en valija (suitcase)',
      'Hip thrust con barra',
      'Hip thrust con mancuerna',
      'Hip thrust en máquina',
      'Hip thrust unilateral',
      'Patada de glúteo en polea',
      'Patada de glúteo en cuadrupedia',
      'Puente de glúteo',
      'Puente de glúteo unilateral',
      'Good morning con barra',
      'Good morning sentado',
      'Curl de femoral tumbado',
      'Curl de femoral sentado',
      'Curl de femoral de pie (máquina)',
      'Curl nórdico',
      'Curl de femoral con pelota suiza',
      'Hiperextensión (espalda baja)',
      'Hiperextensión inversa',
      'Hiperextensión 45°',
      'Superman',
      'Pallof press',
    ];

    for (final name in deadliftNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'isquiotibiales',
        secondaryMuscles: const ['glúteos', 'dorsales', 'erectores'],
        category: ExerciseCategory.deadlift,
        disciplines: const ['powerlifting'],
        equipment: const ['barra'],
        difficulty: _deadliftDifficulty(name),
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Accessory ──────────────────────────────────────────────────────────
    const accessoryNames = [
      'Dominadas',
      'Dominadas con lastre',
      'Dominadas agarre supino (chin-ups)',
      'Jalón al pecho',
      'Jalón al pecho agarre cerrado',
      'Jalón al pecho agarre supino',
      'Jalón al pecho con un brazo',
      'Pullover con mancuerna',
      'Pullover en polea',
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
      'Elevación lateral con mancuernas',
      'Elevación lateral en polea',
      'Elevación frontal con mancuernas',
      'Elevación frontal con barra',
      'Pájaro (elevación posterior)',
      'Pájaro en polea',
      'Curl de bíceps con barra',
      'Curl de bíceps con mancuernas',
      'Curl martillo',
      'Curl martillo con cuerda',
      'Curl predicador (Scott)',
      'Curl concentrado',
      'Curl en polea baja',
      'Curl araña',
      'Encogimientos con barra',
      'Encogimientos con mancuernas',
      'Encogimientos en máquina',
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
      'Gemelos de pie',
      'Gemelos sentado',
      'Gemelos en prensa',
      'Remo ergómetro',
      'Assault bike',
      'Salto a cajón (box jump)',
      'Salto con cuerda',
      'Swing con kettlebell',
      'Turkish get-up',
      'Clean con barra',
      'Push press con barra',
    ];

    for (final name in accessoryNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: _accessoryMuscle(name),
        secondaryMuscles: _accessorySecondary(name),
        category: ExerciseCategory.accessory,
        disciplines: const ['powerlifting', 'culturismo'],
        equipment: const ['barra'],
        difficulty: 2,
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Row (additional standalone) ────────────────────────────────────────
    const rowNames = [
      'Remo pendlay',
      'Remo inclinado con barra',
      'Remo en T (T-bar row)',
      'Remo a un brazo en polea',
      'Remo invertido (Australian pull-up)',
    ];

    for (final name in rowNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'dorsales',
        secondaryMuscles: const ['bíceps', 'romboides'],
        category: ExerciseCategory.row,
        disciplines: const ['powerlifting', 'culturismo'],
        equipment: const ['barra'],
        difficulty: 2,
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Overhead ──────────────────────────────────────────────────────────
    const overheadNames = [
      'Press militar',
      'Press de hombro con barra (OHP)',
      'Press Z (press Zheng)',
      'Push press',
      'Jerk',
    ];

    for (final name in overheadNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'deltoides',
        secondaryMuscles: const ['tríceps', 'trapecio'],
        category: ExerciseCategory.overhead,
        disciplines: const ['powerlifting', 'culturismo'],
        equipment: const ['barra'],
        difficulty: 2,
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Olympic ───────────────────────────────────────────────────────────
    const olympicNames = [
      'Snatch (arrancada)',
      'Clean and Jerk (dos tiempos)',
      'Clean (cargada)',
      'Power clean',
      'Hang clean',
      'Hang power clean',
      'Muscle snatch',
      'Power snatch',
      'Hang snatch',
      'Overhead squat',
    ];

    for (final name in olympicNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'cuádriceps',
        secondaryMuscles: const ['glúteos', 'deltoides', 'trapecio'],
        category: ExerciseCategory.olympic,
        disciplines: const ['olímpico'],
        equipment: const ['barra'],
        difficulty: 5,
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    // ── Carry ─────────────────────────────────────────────────────────────
    const carryNames = [
      'Farmers walk (paseo del granjero)',
      'Farmers walk con mancuernas',
      'Carry con kettlebell',
      'Yoke carry',
      'Suitcase carry',
      'Overhead carry',
    ];

    for (final name in carryNames) {
      result.add(ExerciseDef(
        id: _makeId(name),
        name: name,
        primaryMuscle: 'trapecio',
        secondaryMuscles: const ['core', 'antebrazos', 'dorsales'],
        category: ExerciseCategory.carry,
        disciplines: const ['strongman', 'funcional'],
        equipment: const ['mancuernas'],
        difficulty: 2,
        isCustom: false,
        timestamp: _kTimestamp,
      ));
    }

    return result;
  }
}
