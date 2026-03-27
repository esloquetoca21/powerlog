import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    final auth = context.read<AuthService>();
    final Widget dest = auth.isProfileComplete
        ? const HomeScreen()
        : const RoleSelectionScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
      (_) => false,
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthService>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (ok && mounted) _goToDashboard();
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthService>();
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) _goToDashboard();
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForgotPasswordSheet(prefillEmail: _emailCtrl.text.trim()),
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
                const SizedBox(height: 56),

                // ── Branding ───────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PowerLog',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Cabecera ──────────────────────────────────────────────
                const Text(
                  'Bienvenido de vuelta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inicia sesión para ver tu progreso',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 14),
                ),

                const SizedBox(height: 32),

                // ── Campos ────────────────────────────────────────────────
                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  focusNode: _passwordFocus,
                  onEditingComplete: _signIn,
                  validator: _validatePassword,
                ),

                // ── ¿Olvidaste tu contraseña? ─────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                    ),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Error banner ──────────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  AuthErrorBanner(message: auth.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── Botón principal ───────────────────────────────────────
                PrimaryButton(
                  label: 'Iniciar sesión',
                  onPressed: _signIn,
                  isLoading: auth.isLoading,
                ),

                const SizedBox(height: 24),

                // ── Separador ─────────────────────────────────────────────
                const AuthOrDivider(),

                const SizedBox(height: 24),

                // ── Google ────────────────────────────────────────────────
                GoogleSignInButton(
                  onPressed: _signInWithGoogle,
                  isLoading: auth.isLoading,
                ),

                const SizedBox(height: 40),

                // ── Registro ──────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Introduce tu email';
    if (!v.contains('@') || !v.contains('.')) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Introduce tu contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}

// ── Pantalla recuperación de contraseña ─────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  final String prefillEmail;
  const _ForgotPasswordSheet({this.prefillEmail = ''});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthService>();
    final ok = await auth.resetPassword(email);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Recuperar contraseña',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (!_sent) ...[
            Text(
              'Te enviaremos un enlace para restablecer tu contraseña.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _emailCtrl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onEditingComplete: _send,
            ),
            if (auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              AuthErrorBanner(message: auth.errorMessage!),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Enviar enlace',
              onPressed: _send,
              isLoading: auth.isLoading,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enlace enviado a ${_emailCtrl.text.trim()}. Revisa tu bandeja de entrada.',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}

