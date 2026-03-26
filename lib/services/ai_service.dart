import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/workout_model.dart';

class AiService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  // TODO: Mover a variables de entorno seguras antes de producción
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const String _model = 'claude-haiku-4-5-20251001';

  Future<String?> analyzeWorkout(WorkoutModel workout) async {
    final prompt = _buildWorkoutPrompt(workout);
    return _sendMessage(prompt);
  }

  Future<String?> getTrainingAdvice({
    required List<WorkoutModel> recentWorkouts,
    required String question,
  }) async {
    final context = _buildContextFromWorkouts(recentWorkouts);
    final prompt = '''$context

Pregunta del atleta: $question

Responde en español, de forma concisa y práctica (máximo 150 palabras).''';
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
          'system':
              'Eres un coach experto en powerlifting. Analiza los datos de entrenamiento y da consejos prácticos, concisos y motivadores en español.',
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List<dynamic>;
        return content.first['text'] as String?;
      } else {
        debugPrint('Anthropic API error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error calling Anthropic API: $e');
      return null;
    }
  }

  String _buildWorkoutPrompt(WorkoutModel workout) {
    final buffer = StringBuffer();
    buffer.writeln('Analiza este entrenamiento de powerlifting:');
    buffer.writeln('Fecha: ${workout.date}');
    buffer.writeln('Duración: ${workout.duration?.inMinutes ?? "?"} minutos');
    buffer.writeln('Ejercicios:');

    for (final exercise in workout.exercises) {
      buffer.writeln('\n${exercise.name}:');
      for (final set in exercise.sets) {
        final rpe = set.rpe != null ? ' @ RPE ${set.rpe}' : '';
        buffer.writeln('  - Serie ${set.setNumber}: ${set.weight}kg x ${set.reps}$rpe');
      }
      buffer.writeln('  1RM estimado: ${exercise.bestEstimated1RM.toStringAsFixed(1)}kg');
    }

    buffer.writeln('\nVolumen total: ${workout.totalVolume}kg');
    if (workout.notes != null) buffer.writeln('Notas: ${workout.notes}');
    buffer.writeln('\nDa un análisis breve del entrenamiento con puntos clave y recomendaciones.');
    return buffer.toString();
  }

  String _buildContextFromWorkouts(List<WorkoutModel> workouts) {
    final recent = workouts.take(5).toList();
    final buffer = StringBuffer();
    buffer.writeln('Historial reciente de entrenamiento (últimas ${recent.length} sesiones):');
    for (final w in recent) {
      buffer.writeln('- ${w.date.toLocal()}: ${w.title}, volumen: ${w.totalVolume}kg');
    }
    return buffer.toString();
  }
}
