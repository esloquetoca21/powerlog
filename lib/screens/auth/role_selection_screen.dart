import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';
import 'onboarding_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() => _saving = true);

    final auth = context.read<AuthService>();
    final user = auth.currentUser!;
    await auth.updateProfile(user.copyWith(role: _selected));

    if (!mounted) return;
    setState(() => _saving = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // ── Título ─────────────────────────────────────────────────────
              const Text(
                '¿Cuál es tu rol?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esto personaliza tu experiencia en PowerLog.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
              ),

              const SizedBox(height: 48),

              // ── Opciones ───────────────────────────────────────────────────
              _RoleCard(
                role: UserRole.athlete,
                selected: _selected == UserRole.athlete,
                icon: Icons.fitness_center,
                title: 'Atleta',
                description:
                    'Registra entrenamientos, sigue tu progreso y recibe análisis IA.',
                onTap: () => setState(() => _selected = UserRole.athlete),
              ),

              const SizedBox(height: 16),

              _RoleCard(
                role: UserRole.coach,
                selected: _selected == UserRole.coach,
                icon: Icons.groups_outlined,
                title: 'Entrenador',
                description:
                    'Gestiona atletas, crea macrociclos y comunícate vía chat.',
                onTap: () => setState(() => _selected = UserRole.coach),
              ),

              const Spacer(),

              PrimaryButton(
                label: 'Continuar',
                onPressed: _selected != null ? _continue : null,
                isLoading: _saving,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE53935).withValues(alpha: 0.10)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFFE53935)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE53935).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected
                    ? const Color(0xFFE53935)
                    : Colors.white.withValues(alpha: 0.5),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected
                  ? const Color(0xFFE53935)
                  : Colors.white.withValues(alpha: 0.2),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
