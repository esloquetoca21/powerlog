import 'exercise_model.dart';

/// Definición completa de un ejercicio en la biblioteca.
/// Diferente de ExerciseModel, que es un ejercicio dentro de una sesión (con series).
class ExerciseDef {
  final String id;
  final String name;
  final String? nameEn;
  final String? description;
  final List<String> instructions;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final ExerciseCategory category;
  final List<String> disciplines;
  final List<String> equipment;
  final int difficulty; // 1–5
  final String? videoUrl;
  final List<String> cues;
  final Map<String, int> recommendedRpe; // 'principiante'/'intermedio'/'avanzado' → RPE
  final List<String> tags;
  final bool isCustom;
  final String? createdBy;
  final String timestamp;

  const ExerciseDef({
    required this.id,
    required this.name,
    this.nameEn,
    this.description,
    this.instructions = const [],
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.category,
    this.disciplines = const [],
    this.equipment = const [],
    this.difficulty = 2,
    this.videoUrl,
    this.cues = const [],
    this.recommendedRpe = const {},
    this.tags = const [],
    this.isCustom = false,
    this.createdBy,
    required this.timestamp,
  });

  ExerciseDef copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? description,
    List<String>? instructions,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    ExerciseCategory? category,
    List<String>? disciplines,
    List<String>? equipment,
    int? difficulty,
    String? videoUrl,
    List<String>? cues,
    Map<String, int>? recommendedRpe,
    List<String>? tags,
    bool? isCustom,
    String? createdBy,
    String? timestamp,
  }) {
    return ExerciseDef(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      category: category ?? this.category,
      disciplines: disciplines ?? this.disciplines,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      videoUrl: videoUrl ?? this.videoUrl,
      cues: cues ?? this.cues,
      recommendedRpe: recommendedRpe ?? this.recommendedRpe,
      tags: tags ?? this.tags,
      isCustom: isCustom ?? this.isCustom,
      createdBy: createdBy ?? this.createdBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory ExerciseDef.fromMap(Map<String, dynamic> map) {
    return ExerciseDef(
      id: map['id'] as String,
      name: map['name'] as String,
      nameEn: map['nameEn'] as String?,
      description: map['description'] as String?,
      instructions: List<String>.from(map['instructions'] ?? []),
      primaryMuscle: map['primaryMuscle'] as String? ?? 'varios',
      secondaryMuscles: List<String>.from(map['secondaryMuscles'] ?? []),
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExerciseCategory.accessory,
      ),
      disciplines: List<String>.from(map['disciplines'] ?? []),
      equipment: List<String>.from(map['equipment'] ?? []),
      difficulty: map['difficulty'] as int? ?? 2,
      videoUrl: map['videoUrl'] as String?,
      cues: List<String>.from(map['cues'] ?? []),
      recommendedRpe: (map['recommendedRpe'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
      tags: List<String>.from(map['tags'] ?? []),
      isCustom: map['isCustom'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'instructions': instructions,
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
      'category': category.name,
      'disciplines': disciplines,
      'equipment': equipment,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
      'cues': cues,
      'recommendedRpe': recommendedRpe,
      'tags': tags,
      'isCustom': isCustom,
      'createdBy': createdBy,
      'timestamp': timestamp,
    };
  }

  /// Todos los músculos involucrados (primario + secundarios)
  List<String> get allMuscles => [primaryMuscle, ...secondaryMuscles];

  /// Etiqueta localizada de la categoría
  String get categoryLabel {
    switch (category) {
      case ExerciseCategory.squat:    return 'Sentadilla';
      case ExerciseCategory.bench:    return 'Banca';
      case ExerciseCategory.deadlift: return 'Peso muerto';
      case ExerciseCategory.row:      return 'Remo';
      case ExerciseCategory.overhead: return 'Press OHP';
      case ExerciseCategory.olympic:  return 'Olímpico';
      case ExerciseCategory.carry:    return 'Acarreo';
      case ExerciseCategory.accessory: return 'Accesorio';
    }
  }

  /// Etiqueta corta del nivel de dificultad
  String get difficultyLabel {
    switch (difficulty) {
      case 1: return 'Principiante';
      case 2: return 'Básico';
      case 3: return 'Intermedio';
      case 4: return 'Avanzado';
      case 5: return 'Elite';
      default: return 'Básico';
    }
  }
}

// ── Constantes de músculos disponibles ───────────────────────────────────────

const List<String> kAllMuscles = [
  'cuádriceps',
  'glúteos',
  'glúteo_medio',
  'isquiotibiales',
  'gastrocnemio',
  'sóleo',
  'tibial_anterior',
  'aductores',
  'TFL',
  'recto_abdominal',
  'oblicuos',
  'core',
  'pectoral',
  'pectoral_superior',
  'pectoral_inferior',
  'deltoides',
  'deltoides_anterior',
  'deltoides_lateral',
  'deltoides_posterior',
  'tríceps',
  'bíceps',
  'braquial',
  'braquiorradial',
  'antebrazos',
  'dorsales',
  'trapecio',
  'trapecio_inferior',
  'romboides',
  'erectores',
  'varios',
];

const List<String> kAllEquipment = [
  'barra',
  'mancuernas',
  'kettlebell',
  'máquina',
  'polea',
  'bandas',
  'cadenas',
  'TRX / anillas',
  'peso corporal',
  'cajón',
  'banco',
  'barra EZ',
  'barra hexagonal',
];

const List<String> kAllDisciplines = [
  'powerlifting',
  'culturismo',
  'funcional',
  'calistenia',
  'olímpico',
  'strongman',
];
