import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/session_model.dart';

// Anthropic API — modelo según PRD sección 7: Claude Sonnet 4.6
class AiService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  // TODO: mover a variable de entorno antes de producción
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const String _model = 'claude-sonnet-4-6';

  /// Análisis post-sesión: tonelaje, RPE medio, comparativa e intensidad.
  Future<String?> analyzeSession({
    required SessionModel session,
    SessionModel? previousSession,
  }) async {
    final prompt = _buildSessionPrompt(session, previousSession);
    return _sendMessage(prompt);
  }

  /// Consejo personalizado del coach IA.
  Future<String?> getCoachAdvice({
    required List<SessionModel> recentSessions,
    required String question,
  }) async {
    final context = _buildContext(recentSessions);
    final prompt = '$context\n\nPregunta del atleta: $question\n\n'
        'Responde en español, de forma concisa y práctica (máximo 150 palabras).';
    return _sendMessage(prompt);
  }

  /// Genera un plan de entrenamiento según el método elegido.
  Future<String?> generatePlan({
    required String method, // Sheiko, 5/3/1, Texas Method, GZCLP
    required int weeksToCompetition,
    required double squat1RM,
    required double bench1RM,
    required double deadlift1RM,
  }) async {
    final prompt = '''Genera un plan de entrenamiento de powerlifting con el método $method.
Semanas hasta la competición: $weeksToCompetition
1RM actuales: Sentadilla $squat1RM kg, Banca $bench1RM kg, Peso muerto $deadlift1RM kg

Devuelve el plan en formato estructurado por semanas y días, en español, con series, reps y % de carga.
Incluye bloque de acumulación, intensificación, peaking y descarga.''';
    return _sendMessage(prompt);
  }

  Future<String?> _sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 512,
          'system': 'Eres un coach experto en powerlifting. '
              'Analiza los datos de entrenamiento y da consejos prácticos, '
              'concisos y motivadores en español.',
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        return content.first['text'] as String?;
      }
      debugPrint('Anthropic error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error calling Anthropic API: $e');
      return null;
    }
  }

  String _buildSessionPrompt(SessionModel session, SessionModel? prev) {
    final buf = StringBuffer();
    buf.writeln('Analiza esta sesión de powerlifting:');
    buf.writeln('Título: ${session.title}');
    buf.writeln('Duración: ${session.duration?.inMinutes ?? "?"} minutos');
    buf.writeln('Tonelaje total: ${session.totalVolume} kg');
    if (session.averageRpe != null) {
      buf.writeln('RPE medio: ${session.averageRpe!.toStringAsFixed(1)}');
    }

    for (final ex in session.exercises) {
      buf.writeln('\n${ex.name} (${ex.category.name}):');
      for (final s in ex.sets) {
        final rpe = s.rpe != null ? ' @ RPE ${s.rpe}' : '';
        buf.writeln('  Serie ${s.setNumber}: ${s.weight}kg × ${s.reps}$rpe');
      }
      buf.writeln('  1RM estimado: ${ex.bestEstimated1RM.toStringAsFixed(1)} kg');
    }

    if (prev != null) {
      final diff = session.totalVolume - prev.totalVolume;
      final pct = prev.totalVolume > 0
          ? (diff / prev.totalVolume * 100).toStringAsFixed(1)
          : '0';
      buf.writeln('\nComparación con sesión anterior (${prev.title}):');
      buf.writeln('  Cambio en tonelaje: ${diff > 0 ? '+' : ''}$diff kg ($pct%)');
    }

    buf.writeln('\nDa un análisis breve (máximo 120 palabras) con puntos clave '
        'y recomendaciones para la próxima sesión.');
    return buf.toString();
  }

  String _buildContext(List<SessionModel> sessions) {
    final recent = sessions.take(5).toList();
    final buf = StringBuffer();
    buf.writeln('Historial reciente (últimas ${recent.length} sesiones):');
    for (final s in recent) {
      buf.writeln('- ${s.date.toLocal()}: ${s.title}, tonelaje: ${s.totalVolume} kg'
          '${s.averageRpe != null ? ', RPE medio: ${s.averageRpe!.toStringAsFixed(1)}' : ''}');
    }
    return buf.toString();
  }
}
