/// Calculadoras de powerlifting según el PRD:
/// 1RM (Epley, Brzycki, Lombardi), Wilks y DOTS.
class Calculators {
  Calculators._();

  // ── 1RM ──────────────────────────────────────────────────────────────────

  /// Epley: weight × (1 + reps/30)
  static double epley(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// Brzycki: weight / (1.0278 − 0.0278 × reps)
  static double brzycki(double weight, int reps) {
    if (reps == 1) return weight;
    return weight / (1.0278 - 0.0278 * reps);
  }

  /// Lombardi: weight × reps^0.10
  static double lombardi(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * _pow(reps.toDouble(), 0.10);
  }

  // ── Wilks ─────────────────────────────────────────────────────────────────
  // Coeficientes Wilks 2020 (IPF)

  static const _wilksMaleA = [-216.0475144, 16.2606339, -0.002388645,
      -0.00113732, 7.01863e-6, -1.291e-8];
  static const _wilksFemaleA = [594.31747775582, -27.23842536447, 0.82112226871,
      -0.00930733913, 4.731582e-5, -9.054e-8];

  /// Puntuación Wilks. [bodyWeight] en kg, [total] en kg.
  static double wilks({
    required double bodyWeight,
    required double total,
    required bool isMale,
  }) {
    final a = isMale ? _wilksMaleA : _wilksFemaleA;
    final bw = bodyWeight;
    final denom = a[0] +
        a[1] * bw +
        a[2] * bw * bw +
        a[3] * bw * bw * bw +
        a[4] * bw * bw * bw * bw +
        a[5] * bw * bw * bw * bw * bw;
    return total * (500.0 / denom);
  }

  // ── DOTS ──────────────────────────────────────────────────────────────────
  // Coeficientes DOTS (IPF 2019)

  static const _dotsMaleA = [
    -307.75076, 24.0900756, -0.1918759221, 0.0007391293, -0.000001093
  ];
  static const _dotsFemaleA = [
    -57.96288, 13.6175032, -0.1126655495, 0.0005158568, -0.0000010706
  ];

  /// Puntuación DOTS. [bodyWeight] en kg, [total] en kg.
  static double dots({
    required double bodyWeight,
    required double total,
    required bool isMale,
  }) {
    final a = isMale ? _dotsMaleA : _dotsFemaleA;
    final bw = bodyWeight;
    final denom = a[0] +
        a[1] * bw +
        a[2] * bw * bw +
        a[3] * bw * bw * bw +
        a[4] * bw * bw * bw * bw;
    return total * (500.0 / denom);
  }

  // ── Intentos competición ──────────────────────────────────────────────────

  /// Calcula los tres intentos recomendados dado el 1RM estimado.
  /// Opener: ~90%, Segundo: ~97%, Tercero: ~102%
  static CompetitionAttempts competitionAttempts(double estimated1RM) {
    return CompetitionAttempts(
      opener: _roundTo2_5(estimated1RM * 0.90),
      second: _roundTo2_5(estimated1RM * 0.97),
      third: _roundTo2_5(estimated1RM * 1.02),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _roundTo2_5(double value) {
    return (value / 2.5).round() * 2.5;
  }

  static double _pow(double base, double exp) {
    // Dart's dart:math pow returns num; avoid the import for minimal deps
    return base == 0 ? 0 : _expLog(base, exp);
  }

  static double _expLog(double base, double exp) {
    // Simple approximation sufficient for Lombardi range (reps 1-30)
    return _naturalExp(exp * _naturalLog(base));
  }

  static double _naturalLog(double x) {
    // Taylor series approximation around x=1; accurate for reps 1-30
    if (x <= 0) return double.negativeInfinity;
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSq = term * term;
    double current = term;
    for (int i = 0; i < 30; i++) {
      result += current / (2 * i + 1);
      current *= termSq;
    }
    return 2 * result;
  }

  static double _naturalExp(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i < 30; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}

class CompetitionAttempts {
  final double opener;
  final double second;
  final double third;

  const CompetitionAttempts({
    required this.opener,
    required this.second,
    required this.third,
  });
}
