import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plan_model.dart';
import '../../models/session_model.dart';
import '../../services/auth_service.dart';
import '../../services/plan_service.dart';
import '../../services/session_service.dart';
import '../workout/new_session_screen.dart';
import 'plan_builder_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _weekStart;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _selectedDay = DateTime.now();
  }

  DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  void _goToToday() => setState(() {
        _weekStart = _mondayOf(DateTime.now());
        _selectedDay = DateTime.now();
      });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final planService = context.watch<PlanService>();
    final sessionService = context.watch<SessionService>();

    final userId = auth.currentUser?.uid;
    final activePlan = planService.activePlan;
    final sessions = sessionService.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('Hoy',
                style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Week navigator ───────────────────────────────────────────
          _WeekNavigator(
            weekStart: _weekStart,
            selectedDay: _selectedDay,
            activePlan: activePlan,
            sessions: sessions,
            onPrev: _prevWeek,
            onNext: _nextWeek,
            onDayTap: (d) => setState(() => _selectedDay = d),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: activePlan == null
                ? _NoPlanState(
                    onCreatePlan: userId == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PlanBuilderScreen()),
                            ),
                  )
                : _PlanDayView(
                    plan: activePlan,
                    selectedDay: _selectedDay ?? DateTime.now(),
                    sessions: sessions,
                    onStartSession: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NewSessionScreen()),
                    ),
                    onEditPlan: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PlanBuilderScreen()),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: activePlan != null
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PlanBuilderScreen()),
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              child: const Icon(Icons.edit_outlined,
                  color: Color(0xFFE53935)),
            )
          : null,
    );
  }
}

// ── Week navigator ────────────────────────────────────────────────────────────

class _WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final DateTime? selectedDay;
  final PlanModel? activePlan;
  final List<SessionModel> sessions;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onDayTap;

  const _WeekNavigator({
    required this.weekStart,
    required this.selectedDay,
    required this.activePlan,
    required this.sessions,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];

    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthLabel = weekStart.month == weekEnd.month
        ? '${months[weekStart.month]} ${weekStart.year}'
        : '${months[weekStart.month]}–${months[weekEnd.month]} ${weekStart.year}';

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Month + nav arrows
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right,
                    color: Colors.white54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isToday = day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final isSelected = selectedDay != null &&
                  day.year == selectedDay!.year &&
                  day.month == selectedDay!.month &&
                  day.day == selectedDay!.day;
              final isPlanned = activePlan?.isTrainingDay(day) == true &&
                  activePlan!.containsDate(day);
              final hasSession = sessions.any((s) =>
                  s.date.year == day.year &&
                  s.date.month == day.month &&
                  s.date.day == day.day);

              return GestureDetector(
                onTap: () => onDayTap(day),
                child: Column(
                  children: [
                    Text(dayLabels[i],
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFFE53935)
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : hasSession
                                ? const Color(0xFFE53935).withValues(alpha: 0.15)
                                : isPlanned
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: const Color(0xFFE53935), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Indicator dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasSession
                            ? const Color(0xFFE53935)
                            : isPlanned
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Plan day view ─────────────────────────────────────────────────────────────

class _PlanDayView extends StatelessWidget {
  final PlanModel plan;
  final DateTime selectedDay;
  final List<SessionModel> sessions;
  final VoidCallback onStartSession;
  final VoidCallback onEditPlan;

  const _PlanDayView({
    required this.plan,
    required this.selectedDay,
    required this.sessions,
    required this.onStartSession,
    required this.onEditPlan,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const weekdays = [
      '', 'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo'
    ];

    final isInPlan = plan.containsDate(selectedDay);
    final isTrainingDay = plan.isTrainingDay(selectedDay);
    final completedSession = sessions.firstWhereOrNull((s) =>
        s.date.year == selectedDay.year &&
        s.date.month == selectedDay.month &&
        s.date.day == selectedDay.day);

    final weekNum = isInPlan
        ? ((selectedDay.difference(plan.startDate).inDays ~/ 7) + 1)
            .clamp(1, plan.durationWeeks)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Plan info bar ──────────────────────────────────────────
          _PlanInfoBar(plan: plan, onEdit: onEditPlan),

          const SizedBox(height: 20),

          // ── Day header ─────────────────────────────────────────────
          Text(
            '${weekdays[selectedDay.weekday]}, ${selectedDay.day} de ${months[selectedDay.month]}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold),
          ),
          if (weekNum != null)
            Text(
              'Semana $weekNum de ${plan.durationWeeks}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),

          const SizedBox(height: 20),

          // ── Day content ────────────────────────────────────────────
          if (!isInPlan) ...[
            _InfoCard(
              icon: Icons.calendar_today_outlined,
              text: 'Este día está fuera del rango del plan activo.',
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ] else if (!isTrainingDay) ...[
            _InfoCard(
              icon: Icons.self_improvement,
              text: 'Día de descanso. Recupera bien para el próximo entrenamiento.',
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ] else ...[
            // Training day
            if (completedSession != null) ...[
              _CompletedBadge(),
              const SizedBox(height: 12),
              _CompletedSessionCard(session: completedSession),
            ] else ...[
              _PlannedTrainingCard(
                plan: plan,
                day: selectedDay,
                onStart: onStartSession,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

extension on List<SessionModel> {
  SessionModel? firstWhereOrNull(bool Function(SessionModel) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// ── Plan info bar ─────────────────────────────────────────────────────────────

class _PlanInfoBar extends StatelessWidget {
  final PlanModel plan;
  final VoidCallback onEdit;

  const _PlanInfoBar({required this.plan, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final methodLabel = switch (plan.method) {
      PlanMethod.manual => 'Manual',
      PlanMethod.ai => 'IA',
      PlanMethod.coach => 'Entrenador',
    };
    final methodColor = switch (plan.method) {
      PlanMethod.ai => const Color(0xFF7C4DFF),
      PlanMethod.coach => const Color(0xFF00BCD4),
      PlanMethod.manual => const Color(0xFFE53935),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Semana ${plan.currentWeek} de ${plan.durationWeeks} · $methodLabel',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(methodLabel,
                style: TextStyle(
                    color: methodColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoCard(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Completed badge ───────────────────────────────────────────────────────────

class _CompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 16),
          const SizedBox(width: 6),
          const Text('Entrenamiento completado',
              style: TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Completed session card ────────────────────────────────────────────────────

class _CompletedSessionCard extends StatelessWidget {
  final SessionModel session;
  const _CompletedSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (session.duration != null) ...[
                Icon(Icons.timer_outlined,
                    color: Colors.white.withValues(alpha: 0.4), size: 14),
                const SizedBox(width: 4),
                Text('${session.duration!.inMinutes} min',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12)),
                const SizedBox(width: 12),
              ],
              Icon(Icons.scale_outlined,
                  color: Colors.white.withValues(alpha: 0.4), size: 14),
              const SizedBox(width: 4),
              Text('${session.totalVolume} kg',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
          if (session.exercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: session.exercises
                  .take(4)
                  .map((e) => _Chip(e.name))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style:
              const TextStyle(color: Color(0xFFE53935), fontSize: 11)),
    );
  }
}

// ── Planned training card ─────────────────────────────────────────────────────

class _PlannedTrainingCard extends StatelessWidget {
  final PlanModel plan;
  final DateTime day;
  final VoidCallback onStart;

  const _PlannedTrainingCard({
    required this.plan,
    required this.day,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isToday
                ? const Color(0xFFE53935).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            color: isToday
                ? const Color(0xFFE53935)
                : Colors.white.withValues(alpha: 0.25),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Día de entrenamiento',
            style: TextStyle(
                color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            isToday
                ? '¡Es hoy! Empieza cuando estés listo.'
                : 'Sesión planificada para este día.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (isToday) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Empezar sesión',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── No plan state ─────────────────────────────────────────────────────────────

class _NoPlanState extends StatelessWidget {
  final VoidCallback? onCreatePlan;
  const _NoPlanState({this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined,
                color: Colors.white.withValues(alpha: 0.15), size: 72),
            const SizedBox(height: 20),
            const Text(
              'Sin plan activo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Crea un plan de entrenamiento para organizar tus sesiones semana a semana.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            if (onCreatePlan != null)
              ElevatedButton.icon(
                onPressed: onCreatePlan,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Crear plan',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
