// Colección Firestore: 'plans'

enum PlanMethod { manual, ai, coach }

class PlanModel {
  final String id;
  final String userId;
  final String name;
  final PlanMethod method;
  final DateTime startDate;
  final int durationWeeks;
  final List<int> trainingDays; // 1=lun … 7=dom (weekday)
  final bool isActive;
  final String? notes;
  final DateTime timestamp;

  const PlanModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.method,
    required this.startDate,
    required this.durationWeeks,
    required this.trainingDays,
    this.isActive = true,
    this.notes,
    required this.timestamp,
  });

  PlanModel copyWith({
    String? id,
    String? userId,
    String? name,
    PlanMethod? method,
    DateTime? startDate,
    int? durationWeeks,
    List<int>? trainingDays,
    bool? isActive,
    String? notes,
    DateTime? timestamp,
  }) {
    return PlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      method: method ?? this.method,
      startDate: startDate ?? this.startDate,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      trainingDays: trainingDays ?? this.trainingDays,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      method: PlanMethod.values.firstWhere(
        (m) => m.name == map['method'],
        orElse: () => PlanMethod.manual,
      ),
      startDate: DateTime.parse(map['startDate'] as String),
      durationWeeks: map['durationWeeks'] as int,
      trainingDays: List<int>.from(map['trainingDays'] as List),
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'method': method.name,
      'startDate': startDate.toIso8601String(),
      'durationWeeks': durationWeeks,
      'trainingDays': trainingDays,
      'isActive': isActive,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  DateTime get endDate =>
      startDate.add(Duration(days: durationWeeks * 7 - 1));

  bool isTrainingDay(DateTime date) =>
      trainingDays.contains(date.weekday);

  bool containsDate(DateTime date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);

  int get currentWeek {
    final diff = DateTime.now().difference(startDate).inDays;
    return (diff ~/ 7).clamp(0, durationWeeks - 1) + 1;
  }
}
