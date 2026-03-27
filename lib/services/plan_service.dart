import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/plan_model.dart';

class PlanService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  List<PlanModel> _plans = [];
  bool _isLoading = false;

  List<PlanModel> get plans => _plans;
  bool get isLoading => _isLoading;

  PlanModel? get activePlan {
    try {
      return _plans.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadPlans(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _db
          .collection('plans')
          .where('userId', isEqualTo: userId)
          .limit(20)
          .get();

      _plans = snapshot.docs
          .map((doc) => PlanModel.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error loading plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PlanModel> createPlan({
    required String userId,
    required String name,
    required PlanMethod method,
    required DateTime startDate,
    required int durationWeeks,
    required List<int> trainingDays,
    String? notes,
  }) async {
    // Desactivar plan anterior si existe
    for (final p in _plans.where((p) => p.isActive)) {
      final deactivated = p.copyWith(isActive: false);
      await _db.collection('plans').doc(p.id).set(deactivated.toMap());
    }

    final now = DateTime.now();
    final plan = PlanModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      method: method,
      startDate: startDate,
      durationWeeks: durationWeeks,
      trainingDays: trainingDays,
      isActive: true,
      notes: notes,
      timestamp: now,
    );

    await _db.collection('plans').doc(plan.id).set(plan.toMap());
    _plans = [plan, ..._plans.map((p) => p.copyWith(isActive: false))];
    notifyListeners();
    return plan;
  }

  Future<void> deactivatePlan(String planId) async {
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx == -1) return;
    final updated = _plans[idx].copyWith(isActive: false);
    await _db.collection('plans').doc(planId).set(updated.toMap());
    _plans[idx] = updated;
    notifyListeners();
  }

  Future<void> deletePlan(String planId) async {
    await _db.collection('plans').doc(planId).delete();
    _plans = _plans.where((p) => p.id != planId).toList();
    notifyListeners();
  }
}
