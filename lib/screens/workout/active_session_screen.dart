import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session_service.dart';
import '../../models/exercise_model.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/add_exercise_sheet.dart';
import 'session_detail_screen.dart';

enum _UncompletedAction {
  deleteUncompleted,
  markCompleted,
  keepAsIs,
  continueTraining,
}

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late final Stopwatch _stopwatch;
  late Timer _timer; // no final → permite reiniciar
  String _elapsed = '00:00';

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final m =
          _stopwatch.elapsed.inMinutes.toString().padLeft(2, '0');
      final s = (_stopwatch.elapsed.inSeconds % 60)
          .toString()
          .padLeft(2, '0');
      setState(() => _elapsed = '$m:$s');
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _showAddExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddExerciseSheet(),
    );
  }

  // ── Finalizar sesión ────────────────────────────────────────────────

  Future<void> _finishSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Finalizar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Deseas guardar y finalizar?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Pausar el cronómetro mientras se resuelven series pendientes
    _stopwatch.stop();
    _timer.cancel();

    final shouldProceed = await _handleUncompletedSets();
    if (!mounted) return;

    if (!shouldProceed) {
      // El usuario quiere continuar entrenando → reanudar cronómetro
      _stopwatch.start();
      _startTimer();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            SessionDetailScreen(duration: _stopwatch.elapsed),
      ),
    );
  }

  /// Comprueba si hay series sin completar y muestra el diálogo si las hay.
  /// Devuelve true si se debe proceder a guardar, false si el usuario
  /// elige continuar entrenando.
  Future<bool> _handleUncompletedSets() async {
    final session =
        context.read<SessionService>().activeSession;
    if (session == null) return true;

    final uncompletedCount = session.exercises
        .expand((e) => e.sets)
        .where((s) => !s.completed)
        .length;

    if (uncompletedCount == 0) return true;

    final result = await showDialog<_UncompletedAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UncompletedDialog(count: uncompletedCount),
    );

    if (!mounted) return false;
    if (result == null ||
        result == _UncompletedAction.continueTraining) {
      return false;
    }

    final service = context.read<SessionService>();
    final current = service.activeSession!;

    switch (result) {
      case _UncompletedAction.deleteUncompleted:
        for (final ex in current.exercises) {
          final kept =
              ex.sets.where((s) => s.completed).toList();
          if (kept.length != ex.sets.length) {
            final renumbered = kept
                .asMap()
                .entries
                .map((e) =>
                    e.value.copyWith(setNumber: e.key + 1))
                .toList();
            service
                .updateExercise(ex.copyWith(sets: renumbered));
          }
        }
      case _UncompletedAction.markCompleted:
        for (final ex in current.exercises) {
          if (ex.sets.any((s) => !s.completed)) {
            service.updateExercise(ex.copyWith(
              sets: ex.sets
                  .map((s) => s.copyWith(completed: true))
                  .toList(),
            ));
          }
        }
      case _UncompletedAction.keepAsIs:
      case _UncompletedAction.continueTraining:
        break;
    }

    return true;
  }

  // ── Cancelar sesión ──────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cancelar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '¿Seguro? Perderás los datos de esta sesión.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar sesión',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<SessionService>().cancelSession();
      Navigator.of(context).pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = context.watch<SessionService>();
    final session = sessionService.activeSession;

    if (session == null) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Color(0xFFE53935), size: 16),
                      const SizedBox(width: 4),
                      Text(_elapsed,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: session.exercises.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.white.withOpacity(0.2),
                        size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Añade tu primer ejercicio',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: session.exercises.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExerciseCard(
                      exercise: session.exercises[index]),
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAddExercise,
                    icon: const Icon(Icons.add,
                        color: Color(0xFFE53935)),
                    label: const Text('Ejercicio',
                        style:
                            TextStyle(color: Color(0xFFE53935))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE53935)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: session.exercises.isEmpty
                        ? null
                        : _finishSession,
                    icon: const Icon(Icons.check,
                        color: Colors.white),
                    label: const Text('Finalizar',
                        style:
                            TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Diálogo series sin completar ─────────────────────────────────────────────

class _UncompletedDialog extends StatelessWidget {
  final int count;
  const _UncompletedDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    final plural = count > 1;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      contentPadding:
          const EdgeInsets.fromLTRB(20, 16, 20, 12),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count ${plural ? 'series' : 'serie'} sin marcar',
              style: const TextStyle(
                  color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Qué quieres hacer con ${plural ? 'ellas' : 'ella'}?',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13),
          ),
          const SizedBox(height: 14),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Eliminar las series sin marcar',
            onTap: () => Navigator.pop(
                context, _UncompletedAction.deleteUncompleted),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.check_circle_outline,
            label: 'Marcar todas como realizadas',
            onTap: () => Navigator.pop(
                context, _UncompletedAction.markCompleted),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.radio_button_unchecked,
            label: 'Guardar como no realizadas',
            onTap: () => Navigator.pop(
                context, _UncompletedAction.keepAsIs),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(
                  context, _UncompletedAction.continueTraining),
              child: const Text(
                'Continuar entrenando',
                style: TextStyle(
                    color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de acción en el diálogo ─────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: const Color(0xFFE53935), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
