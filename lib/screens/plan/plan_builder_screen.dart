import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plan_model.dart';
import '../../services/auth_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/primary_button.dart';

class PlanBuilderScreen extends StatefulWidget {
  const PlanBuilderScreen({super.key});

  @override
  State<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends State<PlanBuilderScreen> {
  final _nameCtrl = TextEditingController();

  PlanMethod _method = PlanMethod.manual;
  DateTime _startDate = DateTime.now();
  int _durationWeeks = 8;
  final Set<int> _trainingDays = {1, 3, 5}; // L, X, V por defecto
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE53935),
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Introduce un nombre para el plan');
      return;
    }
    if (_trainingDays.isEmpty) {
      _showSnack('Selecciona al menos un día de entrenamiento');
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final planService = context.read<PlanService>();

    try {
      await planService.createPlan(
        userId: auth.currentUser!.uid,
        name: name,
        method: _method,
        startDate: _startDate,
        durationWeeks: _durationWeeks,
        trainingDays: _trainingDays.toList()..sort(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al guardar el plan');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre ────────────────────────────────────────────────
            _SectionLabel('Nombre del plan'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Ej. Peaking hacia Torrevieja'),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // ── Método ────────────────────────────────────────────────
            _SectionLabel('Método'),
            const SizedBox(height: 8),
            Row(
              children: [
                _MethodCard(
                  label: 'Manual',
                  icon: Icons.edit_outlined,
                  color: const Color(0xFFE53935),
                  description: 'Tú defines los días',
                  selected: _method == PlanMethod.manual,
                  onTap: () =>
                      setState(() => _method = PlanMethod.manual),
                ),
                const SizedBox(width: 10),
                _MethodCard(
                  label: 'IA',
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF7C4DFF),
                  description: 'Generado por Claude',
                  selected: _method == PlanMethod.ai,
                  onTap: () => setState(() => _method = PlanMethod.ai),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Fecha inicio ──────────────────────────────────────────
            _SectionLabel('Fecha de inicio'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickStartDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: Colors.white.withOpacity(0.4), size: 18),
                    const SizedBox(width: 12),
                    Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Duración ──────────────────────────────────────────────
            _SectionLabel('Duración'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [4, 6, 8, 10, 12, 16].map((w) {
                final selected = _durationWeeks == w;
                return GestureDetector(
                  onTap: () => setState(() => _durationWeeks = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE53935).withOpacity(0.12)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFE53935)
                            : Colors.white.withOpacity(0.07),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text('$w sem',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Días de entrenamiento ─────────────────────────────────
            _SectionLabel('Días de entrenamiento'),
            const SizedBox(height: 8),
            _DaySelector(
              selected: _trainingDays,
              onToggle: (day) => setState(() {
                if (_trainingDays.contains(day)) {
                  _trainingDays.remove(day);
                } else {
                  _trainingDays.add(day);
                }
              }),
            ),
            const SizedBox(height: 6),
            Text(
              '${_trainingDays.length} días/semana · '
              '${_trainingDays.length * _durationWeeks} sesiones totales',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 12),
            ),

            const SizedBox(height: 36),

            PrimaryButton(
              label: 'Crear plan',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide:
            const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600));
}

// ── Method card ───────────────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.08)
                : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : Colors.white.withOpacity(0.07),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: selected
                      ? color
                      : Colors.white.withOpacity(0.3),
                  size: 22),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Day selector ──────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _DaySelector({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
            child: GestureDetector(
              onTap: () => onToggle(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE53935)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
