import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/calculators.dart';
import '../../models/exercise_model.dart';
import '../../models/session_model.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ExerciseCategory _selectedLift = ExerciseCategory.squat;

  // ── Data helpers ────────────────────────────────────────────────────────────

  double _bestRM(List<SessionModel> sessions, ExerciseCategory cat) {
    double best = 0;
    for (final s in sessions) {
      for (final e in s.exercises) {
        if (e.category == cat && e.bestEstimated1RM > best) {
          best = e.bestEstimated1RM;
        }
      }
    }
    return best;
  }

  List<_ChartPoint> _progression(
      List<SessionModel> sessions, ExerciseCategory cat) {
    final points = <_ChartPoint>[];
    for (final s in sessions.reversed) {
      double best = 0;
      for (final e in s.exercises) {
        if (e.category == cat && e.bestEstimated1RM > best) {
          best = e.bestEstimated1RM;
        }
      }
      if (best > 0) points.add(_ChartPoint(date: s.date, value: best));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionService>().sessions;
    final user = context.watch<AuthService>().currentUser;

    final squat = _bestRM(sessions, ExerciseCategory.squat);
    final bench = _bestRM(sessions, ExerciseCategory.bench);
    final deadlift = _bestRM(sessions, ExerciseCategory.deadlift);
    final sbdTotal = squat + bench + deadlift;

    final totalVolume = sessions.fold<int>(0, (s, e) => s + e.totalVolume);
    final thisMonth = sessions
        .where((s) {
          final now = DateTime.now();
          return s.date.year == now.year && s.date.month == now.month;
        })
        .length;

    // Wilks / DOTS
    final bw = user?.bodyWeight;
    final isMale = user?.gender != 'female';
    double? wilksScore;
    double? dotsScore;
    if (bw != null && bw > 0 && sbdTotal > 0) {
      wilksScore = Calculators.wilks(
          bodyWeight: bw, total: sbdTotal, isMale: isMale);
      dotsScore = Calculators.dots(
          bodyWeight: bw, total: sbdTotal, isMale: isMale);
    }

    final chartData = _progression(sessions, _selectedLift);

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: sessions.isEmpty
          ? _EmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats globales ──────────────────────────────────────
                  Row(
                    children: [
                      _MiniStat(
                          label: 'Sesiones',
                          value: '${sessions.length}'),
                      const SizedBox(width: 10),
                      _MiniStat(
                          label: 'Este mes',
                          value: '$thisMonth'),
                      const SizedBox(width: 10),
                      _MiniStat(
                          label: 'Volumen total',
                          value: _formatVolume(totalVolume),
                          compact: true),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Récords personales ──────────────────────────────────
                  _SectionTitle('Récords personales (1RM estimado)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RecordCard(
                          label: 'Sentadilla',
                          value: squat,
                          icon: Icons.arrow_downward),
                      const SizedBox(width: 10),
                      _RecordCard(
                          label: 'Banca',
                          value: bench,
                          icon: Icons.horizontal_rule),
                      const SizedBox(width: 10),
                      _RecordCard(
                          label: 'P. muerto',
                          value: deadlift,
                          icon: Icons.arrow_upward),
                    ],
                  ),
                  if (sbdTotal > 0) ...[
                    const SizedBox(height: 10),
                    _TotalCard(total: sbdTotal),
                  ],

                  // ── Wilks / DOTS ────────────────────────────────────────
                  if (wilksScore != null) ...[
                    const SizedBox(height: 24),
                    _SectionTitle('Puntuación relativa'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ScoreCard(
                            label: 'Wilks',
                            value: wilksScore,
                            subtitle: 'Coef. 2020'),
                        const SizedBox(width: 10),
                        _ScoreCard(
                            label: 'DOTS',
                            value: dotsScore!,
                            subtitle: 'IPF 2019'),
                      ],
                    ),
                    if (user?.bodyWeight == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Añade tu peso corporal en el perfil para ver Wilks/DOTS.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 12),
                        ),
                      ),
                  ] else if (bw == null) ...[
                    const SizedBox(height: 24),
                    _SectionTitle('Puntuación relativa'),
                    const SizedBox(height: 10),
                    _NoWeightBanner(),
                  ],

                  const SizedBox(height: 24),

                  // ── Evolución 1RM ───────────────────────────────────────
                  _SectionTitle('Evolución 1RM estimado'),
                  const SizedBox(height: 12),
                  _LiftSelector(
                    selected: _selectedLift,
                    onChanged: (cat) =>
                        setState(() => _selectedLift = cat),
                  ),
                  const SizedBox(height: 12),
                  chartData.length < 2
                      ? _ChartPlaceholder()
                      : _LineChart(points: chartData),
                ],
              ),
            ),
    );
  }

  String _formatVolume(int kg) {
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}t';
    return '${kg}kg';
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600));
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;
  const _MiniStat(
      {required this.label, required this.value, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 14 : 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Record card ───────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  const _RecordCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final hasValue = value > 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: hasValue
              ? Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: hasValue
                    ? const Color(0xFFE53935)
                    : Colors.white.withValues(alpha: 0.2),
                size: 16),
            const SizedBox(height: 8),
            Text(
              hasValue
                  ? '${value.toStringAsFixed(1)} kg'
                  : '—',
              style: TextStyle(
                color: hasValue
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Total card ────────────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${total.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Text('Total SBD estimado',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final String label;
  final double value;
  final String subtitle;
  const _ScoreCard(
      {required this.label,
      required this.value,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── No weight banner ──────────────────────────────────────────────────────────

class _NoWeightBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: Colors.white.withValues(alpha: 0.3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Añade tu peso corporal en el perfil para calcular Wilks y DOTS.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lift selector ─────────────────────────────────────────────────────────────

class _LiftSelector extends StatelessWidget {
  final ExerciseCategory selected;
  final ValueChanged<ExerciseCategory> onChanged;

  const _LiftSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const lifts = [
      (cat: ExerciseCategory.squat, label: 'Sentadilla'),
      (cat: ExerciseCategory.bench, label: 'Banca'),
      (cat: ExerciseCategory.deadlift, label: 'Peso muerto'),
    ];

    return Row(
      children: lifts.map((l) {
        final isSelected = l.cat == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(l.cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE53935)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l.label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Chart point ───────────────────────────────────────────────────────────────

class _ChartPoint {
  final DateTime date;
  final double value;
  const _ChartPoint({required this.date, required this.value});
}

// ── Line chart ────────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<_ChartPoint> points;
  const _LineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: CustomPaint(
        painter: _LineChartPainter(points: points),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<_ChartPoint> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const padLeft = 44.0;
    const padBottom = 28.0;
    const padTop = 8.0;
    const padRight = 8.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    final minV = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final rangeV = (maxV - minV).clamp(1.0, double.infinity);

    final minT = points.first.date.millisecondsSinceEpoch.toDouble();
    final maxT = points.last.date.millisecondsSinceEpoch.toDouble();
    final rangeT = (maxT - minT).clamp(1.0, double.infinity);

    Offset toCanvas(_ChartPoint p) {
      final x = padLeft +
          (p.date.millisecondsSinceEpoch - minT) / rangeT * chartW;
      final y = padTop + (1 - (p.value - minV) / rangeV) * chartH;
      return Offset(x, y);
    }

    // ── Grid lines ───────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final y = padTop + chartH * i / 3;
      canvas.drawLine(
          Offset(padLeft, y), Offset(padLeft + chartW, y), gridPaint);
    }

    // ── Y axis labels ─────────────────────────────────────────────────────────
    final labelStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.35), fontSize: 10);

    for (int i = 0; i <= 3; i++) {
      final val = maxV - (rangeV * i / 3);
      final y = padTop + chartH * i / 3;
      _drawText(
        canvas,
        val.toStringAsFixed(0),
        Offset(0, y - 6),
        42,
        labelStyle,
        TextAlign.right,
      );
    }

    // ── Gradient fill ─────────────────────────────────────────────────────────
    final fillPath = Path();
    fillPath.moveTo(padLeft, padTop + chartH);
    for (final p in points) {
      final pt = toCanvas(p);
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(toCanvas(points.last).dx, padTop + chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE53935).withValues(alpha: 0.18),
            const Color(0xFFE53935).withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTWH(padLeft, padTop, chartW, chartH),
        ),
    );

    // ── Line ──────────────────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final pt = toCanvas(points[i]);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // ── Dots ──────────────────────────────────────────────────────────────────
    final dotPaint = Paint()..color = const Color(0xFFE53935);
    final dotBg = Paint()..color = const Color(0xFF1A1A1A);

    for (final p in points) {
      final pt = toCanvas(p);
      canvas.drawCircle(pt, 5, dotBg);
      canvas.drawCircle(pt, 3.5, dotPaint);
    }

    // ── X axis date labels (first and last) ───────────────────────────────────
    if (points.isNotEmpty) {
      final first = points.first;
      final last = points.last;

      _drawText(
        canvas,
        _shortDate(first.date),
        Offset(padLeft, size.height - padBottom + 6),
        50,
        labelStyle,
        TextAlign.left,
      );

      if (points.length > 1) {
        _drawText(
          canvas,
          _shortDate(last.date),
          Offset(size.width - padRight - 46, size.height - padBottom + 6),
          50,
          labelStyle,
          TextAlign.right,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, double width,
      TextStyle style, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    tp.paint(canvas, offset);
  }

  String _shortDate(DateTime d) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month]}';
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.points != points;
}

// ── Chart placeholder ─────────────────────────────────────────────────────────

class _ChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart,
                color: Colors.white.withValues(alpha: 0.15), size: 40),
            const SizedBox(height: 8),
            Text(
              'Registra más sesiones para\nver la evolución de tu 1RM',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart,
              color: Colors.white.withValues(alpha: 0.15), size: 64),
          const SizedBox(height: 16),
          Text(
            'Sin datos aún',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Guarda sesiones de entrenamiento\npara ver tu progreso aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
