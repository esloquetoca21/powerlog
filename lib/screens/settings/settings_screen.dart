import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Unidades ──────────────────────────────────────────────────
            _SectionTitle('Unidades'),
            const SizedBox(height: 10),
            _ToggleTile(
              icon: Icons.monitor_weight_outlined,
              label: 'Mostrar pesos en kilogramos',
              subtitle: settings.useKg
                  ? 'Usando kg'
                  : 'Usando lb',
              value: settings.useKg,
              onChanged: (v) => settings.setUseKg(v),
            ),

            const SizedBox(height: 24),

            // ── Notificaciones ────────────────────────────────────────────
            _SectionTitle('Notificaciones'),
            const SizedBox(height: 10),
            _ToggleTile(
              icon: Icons.notifications_outlined,
              label: 'Notificaciones push',
              subtitle: settings.notificationsEnabled
                  ? 'Activadas'
                  : 'Desactivadas',
              value: settings.notificationsEnabled,
              onChanged: (v) => settings.setNotificationsEnabled(v),
            ),

            const SizedBox(height: 24),

            // ── Cuenta ────────────────────────────────────────────────────
            _SectionTitle('Cuenta'),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.lock_outline,
              label: 'Cambiar contraseña',
              color: Colors.white,
              onTap: () => _changePassword(context),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.delete_forever_outlined,
              label: 'Eliminar cuenta',
              color: const Color(0xFFE53935),
              onTap: () => _deleteAccount(context),
            ),

            const SizedBox(height: 24),

            // ── Información ───────────────────────────────────────────────
            _SectionTitle('Información'),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.info_outline,
              label: 'Versión',
              value: '1.0.0 (1)',
            ),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.code_outlined,
              label: 'Desarrollado con',
              value: 'Flutter + Firebase',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final auth = context.read<AuthService>();
    final email = auth.currentUser?.email;
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cambiar contraseña',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Te enviaremos un correo a $email con un enlace para restablecer tu contraseña.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar correo',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await auth.sendPasswordResetEmail(email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo enviado. Revisa tu bandeja de entrada.'),
          backgroundColor: Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el correo. Inténtalo de nuevo.'),
          backgroundColor: Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar cuenta',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acción es irreversible. Se eliminarán todos tus datos: sesiones, planes y perfil.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar cuenta',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AuthService>().deleteAccount();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo eliminar la cuenta. Vuelve a iniciar sesión e inténtalo de nuevo.'),
          backgroundColor: Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600),
      );
}

// ── Toggle tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFE53935),
          ),
        ],
      ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            const Spacer(),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.25), size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
