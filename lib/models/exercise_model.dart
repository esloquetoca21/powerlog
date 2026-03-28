import 'set_model.dart';

enum ExerciseCategory {
  squat,     // Sentadilla
  bench,     // Press banca
  deadlift,  // Peso muerto
  row,       // Remo / tracción horizontal
  overhead,  // Press por encima de la cabeza
  accessory, // Accesorios generales
  olympic,   // Levantamiento olímpico
  carry,     // Acarreos
}

class ExerciseModel {
  final String id;
  final String name;
  final ExerciseCategory category;
  final List<SetModel> sets;
  final String? notes;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.sets,
    this.notes,
  });

  ExerciseModel copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    List<SetModel>? sets,
    String? notes,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExerciseCategory.accessory,
      ),
      sets: (map['sets'] as List<dynamic>)
          .map((s) => SetModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
    };
  }

  double get maxWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  double get bestEstimated1RM =>
      sets.isEmpty ? 0 : sets.map((s) => s.estimated1RM).reduce((a, b) => a > b ? a : b);

  /// Tonelaje total: suma de (peso × reps) por cada serie
  int get totalVolume =>
      sets.fold(0, (sum, s) => sum + (s.weight * s.reps).round());

  /// RPE medio ponderado por el número de reps
  double? get averageRpe {
    final setsWithRpe = sets.where((s) => s.rpe != null).toList();
    if (setsWithRpe.isEmpty) return null;
    final totalRpe = setsWithRpe.fold(0.0, (sum, s) => sum + s.rpe!);
    return totalRpe / setsWithRpe.length;
  }
}
