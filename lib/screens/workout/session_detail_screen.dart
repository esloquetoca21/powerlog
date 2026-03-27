import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_model.dart';
import '../../models/session_model.dart';
import '../../services/ai_service.dart';
import '../../services/session_service.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final Duration duration;

  const SessionDetailScreen({super.key, required this.duration});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _notesCtrl = TextEditingController();
  final _aiService = AiService();

  String? _aiInsights;
  bool _aiLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAiInsights();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAiInsights() async {
    final session = context.read<SessionService>().activeSession;
    if (session == null) return;

    try {
      final result = await _aiService.analyzeSession(session: session);
      if (mounted) setState(() => _aiInsights = result);
    } catch (_) {
      // API key no configurada — se muestra mensaje vacío
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final sessionService = context.read<SessionService>();
    try {
      await sessionService.finishSession(
        duration: widget.duration,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        aiInsights: _aiInsights,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: const Color(0xFF1A1A1A),
        ),
      );
      setState(() => _saving = false);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Descartar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            '¿Seguro? La sesión no se guardará.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<SessionService>().cancelSession();
    }
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>().activeSession;
    if (session == null) return const SizedBox.shrink();

    final totalSets = session.exercises.fold<int>(
      0, (sum, e) => sum + e.sets.length,
    );
    final minutes = widget.duration.inMinutes;
    final seconds = widget.duration.inSeconds % 60;
    final durationStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async => await _onWillPop(),
          ),
          title: const Text('Resumen de sesión'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ───────────────────────────────────────────────────
              Text(
                session.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(session.date),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),

              const SizedBox(height: 20),

              // ── Stats ────────────────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    icon: Icons.timer_outlined,
                    label: 'Duración',
                    value: durationStr,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.fitness_center,
                    label: 'Ejercicios',
                    value: '${session.exercises.length}',
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.repeat,
                    label: 'Series',
                    value: '$totalSets',
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.scale_outlined,
                    label: 'Volumen',
                    value: '${session.totalVolume} kg',
                    compact: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Mejores levantamientos ────────────────────────────────────
              _BestLiftsSection(session: session),

              const SizedBox(height: 24),

              // ── Ejercicios ───────────────────────────────────────────────
              _SectionTitle('Ejercicios'),
              const SizedBox(height: 10),
              ...session.exercises.map((e) => _ExerciseSummaryRow(exercise: e)),

              const SizedBox(height: 24),

              // ── Análisis IA ──────────────────────────────────────────────
              _AiInsightsCard(
                loading: _aiLoading,
                insights: _aiInsights,
              ),

              const SizedBox(height: 24),

              // ── Notas ────────────────────────────────────────────────────
              _SectionTitle('Notas (opcional)'),
              const SizedBox(height: 10),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cómo te has sentido, qué mejorar...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFFE53935), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: 'Guardar sesión',
              onPressed: _save,
              isLoading: _saving,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final weekdays = [
      '', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes',
      'sábado', 'domingo'
    ];
    return '${weekdays[date.weekday]}, ${date.day} de ${months[date.month]}';
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE53935), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Best lifts section ────────────────────────────────────────────────────────

class _BestLiftsSection extends StatelessWidget {
  final SessionModel session;
  const _BestLiftsSection({required this.session});

  @override
  Widget build(BuildContext context) {
    final sbd = <String, double>{};
    for (final ex in session.exercises) {
      final rm = ex.bestEstimated1RM;
      if (rm <= 0) continue;
      if (ex.category == ExerciseCategory.squat &&
          (sbd['Sentadilla'] == null || rm > sbd['Sentadilla']!)) {
        sbd['Sentadilla'] = rm;
      } else if (ex.category == ExerciseCategory.bench &&
          (sbd['Banca'] == null || rm > sbd['Banca']!)) {
        sbd['Banca'] = rm;
      } else if (ex.category == ExerciseCategory.deadlift &&
          (sbd['Peso muerto'] == null || rm > sbd['Peso muerto']!)) {
        sbd['Peso muerto'] = rm;
      }
    }
    if (sbd.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Mejores 1RM estimados'),
        const SizedBox(height: 10),
        Row(
          children: sbd.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${entry.value.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.key,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Exercise summary row ──────────────────────────────────────────────────────

class _ExerciseSummaryRow extends StatelessWidget {
  final ExerciseModel exercise;
  const _ExerciseSummaryRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final best = exercise.sets.isEmpty
        ? null
        : exercise.sets.reduce(
            (a, b) => a.weight > b.weight ? a : b,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.sets.length} series · ${exercise.totalVolume} kg tonelaje',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          if (best != null)
            Text(
              '${best.weight.toStringAsFixed(best.weight % 1 == 0 ? 0 : 1)} kg × ${best.reps}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ── AI insights card ──────────────────────────────────────────────────────────

class _AiInsightsCard extends StatelessWidget {
  final bool loading;
  final String? insights;

  const _AiInsightsCard({required this.loading, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFE53935), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Análisis IA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analizando tu sesión...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
              ],
            )
          else if (insights != null)
            Text(
              insights!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.5,
              ),
            )
          else
            Text(
              'Configura tu API key de Anthropic en ai_service.dart para obtener análisis personalizados de cada sesión.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
