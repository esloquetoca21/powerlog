import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/workout_service.dart';
import '../../models/workout_model.dart';
import 'active_workout_screen.dart';

class NewWorkoutScreen extends StatefulWidget {
  const NewWorkoutScreen({super.key});

  @override
  State<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  final _titleController = TextEditingController();

  static const List<String> _quickTemplates = [
    'Sentadilla / Press / Peso Muerto',
    'Día de Sentadilla',
    'Día de Banca',
    'Día de Peso Muerto',
    'Entrenamiento Accesorio',
    'Peaking Session',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _start(String title) {
    if (title.trim().isEmpty) return;
    final auth = context.read<AuthService>();
    context.read<WorkoutService>().startWorkout(
          userId: auth.currentUser!.uid,
          title: title.trim(),
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo entrenamiento')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre del entrenamiento',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Día de banca',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: Color(0xFFE53935)),
                  onPressed: () => _start(_titleController.text),
                ),
              ),
              onSubmitted: _start,
            ),
            const SizedBox(height: 28),
            const Text(
              'Plantillas rápidas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _quickTemplates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final template = _quickTemplates[index];
                  return InkWell(
                    onTap: () => _start(template),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt,
                              color: Color(0xFFE53935), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              template,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.white.withOpacity(0.3)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
