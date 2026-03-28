import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';
import '../home/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();

  String? _gender;
  String? _level;
  String? _federation;
  String? _category;
  DateTime? _competitionDate;
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCompetitionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE53935),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _competitionDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showSnack('Selecciona tu género');
      return;
    }
    if (_level == null) {
      _showSnack('Selecciona tu nivel');
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final user = auth.currentUser!;

    final updated = user.copyWith(
      gender: _gender,
      bodyWeight: _weightCtrl.text.isNotEmpty
          ? double.tryParse(_weightCtrl.text.replaceAll(',', '.'))
          : null,
      level: _level,
      federation: _federation?.trim().isEmpty ?? true ? null : _federation,
      category: _category?.trim().isEmpty ?? true ? null : _category,
      competitionDate: _competitionDate,
      onboardingCompleted: true,
    );

    await auth.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Título ─────────────────────────────────────────────────
                const Text(
                  'Completa tu perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estos datos nos ayudan a personalizar tus cálculos y recomendaciones.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
                ),

                const SizedBox(height: 36),

                // ── Peso corporal ──────────────────────────────────────────
                const _SectionLabel('Peso corporal (kg)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Ej. 83.5'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null; // opcional
                    final parsed =
                        double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0 || parsed > 400) {
                      return 'Introduce un peso válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Género ─────────────────────────────────────────────────
                const _SectionLabel('Género'),
                const SizedBox(height: 8),
                _ChipGroup(
                  options: const ['Hombre', 'Mujer', 'Otro'],
                  values: const ['male', 'female', 'other'],
                  selected: _gender,
                  onSelected: (v) => setState(() => _gender = v),
                ),

                const SizedBox(height: 24),

                // ── Nivel ──────────────────────────────────────────────────
                const _SectionLabel('Nivel'),
                const SizedBox(height: 8),
                _ChipGroup(
                  options: const [
                    'Principiante',
                    'Intermedio',
                    'Avanzado',
                    'Competidor'
                  ],
                  values: const [
                    'principiante',
                    'intermedio',
                    'avanzado',
                    'competidor'
                  ],
                  selected: _level,
                  onSelected: (v) => setState(() => _level = v),
                ),

                const SizedBox(height: 24),

                // ── Federación ─────────────────────────────────────────────
                const _SectionLabel('Federación (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Ej. FEPE, IPF España, WRPF'),
                  onChanged: (v) => _federation = v,
                ),

                const SizedBox(height: 24),

                // ── Categoría de peso ──────────────────────────────────────
                const _SectionLabel('Categoría de peso (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Ej. -83 kg, +120 kg'),
                  onChanged: (v) => _category = v,
                ),

                const SizedBox(height: 24),

                // ── Próxima competición ────────────────────────────────────
                const _SectionLabel('Próxima competición (opcional)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickCompetitionDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: Colors.white.withValues(alpha: 0.4), size: 18),
                        const SizedBox(width: 12),
                        Text(
                          _competitionDate != null
                              ? '${_competitionDate!.day}/${_competitionDate!.month}/${_competitionDate!.year}'
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            color: _competitionDate != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                        ),
                        if (_competitionDate != null) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _competitionDate = null),
                            child: Icon(Icons.close,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                PrimaryButton(
                  label: 'Empezar a entrenar',
                  onPressed: _save,
                  isLoading: _saving || auth.isLoading,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 12),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Chip group ────────────────────────────────────────────────────────────────

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ChipGroup({
    required this.options,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final isSelected = selected == values[i];
        return GestureDetector(
          onTap: () => onSelected(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE53935).withValues(alpha: 0.12)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE53935)
                    : Colors.white.withValues(alpha: 0.07),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              options[i],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
