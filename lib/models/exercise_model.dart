import 'package:equatable/equatable.dart';

enum ExerciseCategory { squat, bench, deadlift, accessory }

class SetModel extends Equatable {
  final int setNumber;
  final double weight;
  final int reps;
  final double? rpe; // Rate of Perceived Exertion (1-10)
  final bool completed;

  const SetModel({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.rpe,
    this.completed = false,
  });

  SetModel copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    bool? completed,
  }) {
    return SetModel(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      completed: completed ?? this.completed,
    );
  }

  factory SetModel.fromMap(Map<String, dynamic> map) {
    return SetModel(
      setNumber: map['setNumber'] as int,
      weight: (map['weight'] as num).toDouble(),
      reps: map['reps'] as int,
      rpe: map['rpe'] != null ? (map['rpe'] as num).toDouble() : null,
      completed: map['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'completed': completed,
    };
  }

  // Calcular 1RM estimado con la fórmula de Epley
  double get estimated1RM {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  @override
  List<Object?> get props => [setNumber, weight, reps, rpe, completed];
}

class ExerciseModel extends Equatable {
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

  int get totalVolume =>
      sets.fold(0, (sum, s) => sum + (s.weight * s.reps).round());

  @override
  List<Object?> get props => [id, name, category, sets, notes];
}
