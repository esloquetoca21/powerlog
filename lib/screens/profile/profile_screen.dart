import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  // Edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _federationCtrl;
  late TextEditingController _categoryCtrl;

  String? _gender;
  String? _level;
  DateTime? _competitionDate;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser!;
    _nameCtrl = TextEditingController(text: user.displayName);
    _weightCtrl = TextEditingController(
        text: user.bodyWeight?.toString() ?? '');
    _federationCtrl =
        TextEditingController(text: user.federation ?? '');
    _categoryCtrl =
        TextEditingController(text: user.category ?? '');
    _gender = user.gender;
    _level = user.level;
    _competitionDate = user.competitionDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _federationCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _startEdit() {
    final user = context.read<AuthService>().currentUser!;
    _nameCtrl.text = user.displayName;
    _weightCtrl.text = user.bodyWeight?.toString() ?? '';
    _federationCtrl.text = user.federation ?? '';
    _categoryCtrl.text = user.category ?? '';
    _gender = user.gender;
    _level = user.level;
    _competitionDate = user.competitionDate;
    setState(() => _editing = true);
  }

  void _cancelEdit() => setState(() => _editing = false);

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('El nombre no puede estar vacío');
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    final user = auth.currentUser!;

    final updated = user.copyWith(
      displayName: _nameCtrl.text.trim(),
      gender: _gender,
      bodyWeight: _weightCtrl.text.isNotEmpty
          ? double.tryParse(_weightCtrl.text.replaceAll(',', '.'))
          : null,
      level: _level,
      federation: _federationCtrl.text.trim().isEmpty
          ? null
          : _federationCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty
          ? null
          : _categoryCtrl.text.trim(),
      competitionDate: _competitionDate,
    );

    try {
      await auth.updateProfile(updated);
      if (!mounted) return;
      setState(() => _editing = false);
      _showSnack('Perfil actualizado');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Error al guardar. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _competitionDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE53935),
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _competitionDate = picked);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres cerrar sesión?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;
    final sessions = context.watch<SessionService>().sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: _startEdit,
              child: const Text('Editar',
                  style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600)),
            )
          else ...[
            TextButton(
              onPressed: _cancelEdit,
              child: Text('Cancelar',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5))),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + nombre ────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  _Avatar(name: user.displayName),
                  const SizedBox(height: 12),
                  if (!_editing)
                    Text(
                      user.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  else
                    SizedBox(
                      width: 220,
                      child: _EditField(
                        controller: _nameCtrl,
                        hint: 'Nombre',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 6),
                  _RoleBadge(role: user.role),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats ──────────────────────────────────────────────────
            if (!_editing) ...[
              Row(
                children: [
                  _StatTile(
                      label: 'Sesiones',
                      value: '${sessions.length}'),
                  const SizedBox(width: 10),
                  _StatTile(
                    label: 'Miembro desde',
                    value: _memberSince(user.createdAt),
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ── Datos del atleta ───────────────────────────────────────
            const _SectionTitle('Datos del atleta'),
            const SizedBox(height: 12),

            _editing
                ? _EditableFields(
                    weightCtrl: _weightCtrl,
                    federationCtrl: _federationCtrl,
                    categoryCtrl: _categoryCtrl,
                    gender: _gender,
                    level: _level,
                    competitionDate: _competitionDate,
                    onGenderChanged: (v) =>
                        setState(() => _gender = v),
                    onLevelChanged: (v) =>
                        setState(() => _level = v),
                    onPickDate: _pickDate,
                    onClearDate: () =>
                        setState(() => _competitionDate = null),
                  )
                : _ViewFields(user: user),

            const SizedBox(height: 32),

            // ── Guardar (solo en modo edición) ─────────────────────────
            if (_editing) ...[
              PrimaryButton(
                label: 'Guardar cambios',
                onPressed: _save,
                isLoading: _saving,
              ),
              const SizedBox(height: 16),
            ],

            // ── Cuenta ─────────────────────────────────────────────────
            if (!_editing) ...[
              const _SectionTitle('Cuenta'),
              const SizedBox(height: 12),
              _ActionRow(
                icon: Icons.settings_outlined,
                label: 'Ajustes',
                color: Colors.white,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                color: const Color(0xFFE53935),
                onTap: _signOut,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _memberSince(DateTime date) {
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${months[date.month]} ${date.year}';
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase();
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = role == UserRole.coach ? 'Entrenador' : 'Atleta';
    final icon =
        role == UserRole.coach ? Icons.groups_outlined : Icons.fitness_center;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;
  const _StatTile(
      {required this.label, required this.value, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
                    fontSize: compact ? 15 : 22,
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

// ── View fields ───────────────────────────────────────────────────────────────

class _ViewFields extends StatelessWidget {
  final UserModel user;
  const _ViewFields({required this.user});

  @override
  Widget build(BuildContext context) {
    final genderLabel = switch (user.gender) {
      'male' => 'Hombre',
      'female' => 'Mujer',
      'other' => 'Otro',
      _ => null,
    };
    final levelLabel = switch (user.level) {
      'principiante' => 'Principiante',
      'intermedio' => 'Intermedio',
      'avanzado' => 'Avanzado',
      'competidor' => 'Competidor',
      _ => null,
    };

    return Column(
      children: [
        _InfoRow(
            label: 'Peso corporal',
            value: user.bodyWeight != null
                ? '${user.bodyWeight} kg'
                : null),
        _InfoRow(label: 'Género', value: genderLabel),
        _InfoRow(label: 'Nivel', value: levelLabel),
        _InfoRow(label: 'Federación', value: user.federation),
        _InfoRow(label: 'Categoría', value: user.category),
        _InfoRow(
          label: 'Próxima competición',
          value: user.competitionDate != null
              ? _formatDate(user.competitionDate!)
              : null,
          highlight: user.competitionDate != null,
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final diff = d.difference(DateTime.now()).inDays;
    final diffStr = diff > 0 ? ' ($diff días)' : '';
    return '${d.day} de ${months[d.month]} de ${d.year}$diffStr';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool highlight;
  const _InfoRow(
      {required this.label, this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13)),
          ),
          Text(
            value ?? '—',
            style: TextStyle(
              color: value != null
                  ? (highlight
                      ? const Color(0xFFE53935)
                      : Colors.white)
                  : Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
              fontWeight:
                  value != null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Editable fields ───────────────────────────────────────────────────────────

class _EditableFields extends StatelessWidget {
  final TextEditingController weightCtrl;
  final TextEditingController federationCtrl;
  final TextEditingController categoryCtrl;
  final String? gender;
  final String? level;
  final DateTime? competitionDate;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _EditableFields({
    required this.weightCtrl,
    required this.federationCtrl,
    required this.categoryCtrl,
    required this.gender,
    required this.level,
    required this.competitionDate,
    required this.onGenderChanged,
    required this.onLevelChanged,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Peso corporal (kg)'),
        const SizedBox(height: 6),
        _EditField(
          controller: weightCtrl,
          hint: 'Ej. 83.5',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
          ],
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Género'),
        const SizedBox(height: 6),
        _ChipRow(
          options: const ['Hombre', 'Mujer', 'Otro'],
          values: const ['male', 'female', 'other'],
          selected: gender,
          onSelected: onGenderChanged,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Nivel'),
        const SizedBox(height: 6),
        _ChipRow(
          options: const [
            'Principiante', 'Intermedio', 'Avanzado', 'Competidor'
          ],
          values: const [
            'principiante', 'intermedio', 'avanzado', 'competidor'
          ],
          selected: level,
          onSelected: onLevelChanged,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Federación (opcional)'),
        const SizedBox(height: 6),
        _EditField(controller: federationCtrl, hint: 'Ej. FEPE, IPF'),
        const SizedBox(height: 16),
        const _FieldLabel('Categoría de peso (opcional)'),
        const SizedBox(height: 6),
        _EditField(controller: categoryCtrl, hint: 'Ej. -83 kg'),
        const SizedBox(height: 16),
        const _FieldLabel('Próxima competición (opcional)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPickDate,
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
                    color: Colors.white.withValues(alpha: 0.4), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    competitionDate != null
                        ? '${competitionDate!.day}/${competitionDate!.month}/${competitionDate!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: competitionDate != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (competitionDate != null)
                  GestureDetector(
                    onTap: onClearDate,
                    child: Icon(Icons.close,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500));
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  const _EditField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
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
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 13),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ChipRow({
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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
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
            child: Text(options[i],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                )),
          ),
        );
      }),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
