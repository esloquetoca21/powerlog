import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../workout/new_session_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _weeklyStreak(List<SessionModel> sessions) {
    if (sessions.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    // Semana actual = semana 0, semana anterior = semana -1, etc.
    for (int week = 0; week <= 52; week++) {
      final weekStart = _mondayOf(now.subtract(Duration(days: week * 7)));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final hasSession = sessions.any(
        (s) => s.date.isAfter(weekStart) && s.date.isBefore(weekEnd),
      );
      if (hasSession) {
        streak++;
      } else if (week > 0) {
        // Semana actual sin sesión no rompe racha
        break;
      }
    }
    return streak;
  }

  DateTime _mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<SessionModel> _sessionsThisWeek(List<SessionModel> sessions) {
    final monday = _mondayOf(DateTime.now());
    final sunday = monday.add(const Duration(days: 7));
    return sessions
        .where((s) => s.date.isAfter(monday) && s.date.isBefore(sunday))
        .toList();
  }

  List<bool> _weekActivity(List<SessionModel> sessions) {
    final monday = _mondayOf(DateTime.now());
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return sessions.any((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionService>().sessions;
    final user = context.watch<AuthService>().currentUser;
    final now = DateTime.now();

    final weekSessions = _sessionsThisWeek(sessions);
    final weekVolume =
        weekSessions.fold<int>(0, (s, e) => s + e.totalVolume);
    final streak = _weeklyStreak(sessions);
    final activity = _weekActivity(sessions);
    final lastSession = sessions.isNotEmpty ? sessions.first : null;

    // Días hasta competición
    final compDate = user?.competitionDate;
    final daysToComp =
        compDate != null ? compDate.difference(now).inDays : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user?.displayName.split(' ').first ?? "Atleta"} 👋',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _formatToday(now),
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Competición countdown ──────────────────────────────────
            if (daysToComp != null && daysToComp >= 0) ...[
              _CompetitionCard(days: daysToComp, date: compDate!),
              const SizedBox(height: 16),
            ],

            // ── Stats row ──────────────────────────────────────────────
            Row(
              children: [
                _StatCard(
                  icon: Icons.local_fire_department,
                  iconColor: const Color(0xFFFF6B35),
                  label: 'Racha',
                  value: '$streak',
                  unit: streak == 1 ? 'semana' : 'semanas',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.fitness_center,
                  iconColor: const Color(0xFFE53935),
                  label: 'Esta semana',
                  value: '${weekSessions.length}',
                  unit: weekSessions.length == 1 ? 'sesión' : 'sesiones',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.scale_outlined,
                  iconColor: const Color(0xFF4CAF50),
                  label: 'Volumen',
                  value: weekVolume >= 1000
                      ? '${(weekVolume / 1000).toStringAsFixed(1)}t'
                      : '${weekVolume}kg',
                  unit: 'esta semana',
                  compact: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Actividad semanal ──────────────────────────────────────
            _SectionTitle('Actividad esta semana'),
            const SizedBox(height: 10),
            _WeekActivity(activity: activity),

            const SizedBox(height: 24),

            // ── Última sesión ──────────────────────────────────────────
            _SectionTitle('Última sesión'),
            const SizedBox(height: 10),
            lastSession == null
                ? _EmptyLastSession()
                : _LastSessionCard(session: lastSession),

            const SizedBox(height: 24),

            // ── Acceso rápido ──────────────────────────────────────────
            _SectionTitle('Acceso rápido'),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.add_circle_outline,
              label: 'Nueva sesión',
              subtitle: 'Empieza a entrenar ahora',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const NewSessionScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatToday(DateTime d) {
    const weekdays = [
      '', 'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo'
    ];
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${weekdays[d.weekday]}, ${d.day} de ${months[d.month]}';
  }
}

// ── Competition card ──────────────────────────────────────────────────────────

class _CompetitionCard extends StatelessWidget {
  final int days;
  final DateTime date;
  const _CompetitionCard({required this.days, required this.date});

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE53935).withOpacity(0.15),
            const Color(0xFFE53935).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: Color(0xFFE53935), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Próxima competición',
                    style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  days == 0
                      ? '¡Hoy es el día!'
                      : '$days días restantes',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${date.day} ${months[date.month]} ${date.year}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 16 : 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            Text(unit,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Week activity ─────────────────────────────────────────────────────────────

class _WeekActivity extends StatelessWidget {
  final List<bool> activity; // 7 elements, Mon–Sun
  const _WeekActivity({required this.activity});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final today = DateTime.now().weekday - 1; // 0=Mon

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final isToday = i == today;
          final trained = activity[i];
          final isFuture = i > today;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: trained
                      ? const Color(0xFFE53935)
                      : isFuture
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(
                          color: const Color(0xFFE53935), width: 2)
                      : null,
                ),
                child: Center(
                  child: trained
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : isFuture
                          ? null
                          : const Icon(Icons.remove,
                              color: Colors.white24, size: 14),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                days[i],
                style: TextStyle(
                  color: isToday
                      ? const Color(0xFFE53935)
                      : Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Last session card ─────────────────────────────────────────────────────────

class _LastSessionCard extends StatelessWidget {
  final SessionModel session;
  const _LastSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final duration = session.duration != null
        ? '${session.duration!.inMinutes} min'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (duration != null)
                Text(duration,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _daysAgo(session.date),
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12),
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
          if (session.totalVolume > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.bar_chart,
                    color: Color(0xFFE53935), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${session.totalVolume} kg tonelaje',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _daysAgo(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return 'Hace $diff días';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFFE53935), fontSize: 11)),
    );
  }
}

// ── Empty last session ────────────────────────────────────────────────────────

class _EmptyLastSession extends StatelessWidget {
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
          Icon(Icons.fitness_center,
              color: Colors.white.withOpacity(0.15), size: 36),
          const SizedBox(height: 8),
          Text(
            'Sin sesiones aún',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Quick action ──────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, color: const Color(0xFFE53935), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600));
}
