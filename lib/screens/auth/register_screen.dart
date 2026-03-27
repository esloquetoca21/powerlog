import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/auth_widgets.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import 'role_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthService>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );
    if (ok && mounted) _goToDashboard();
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthService>();
    final ok = await auth.signInWithGoogle();
    if (ok && mounted) _goToDashboard();
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
                const SizedBox(height: 16),

                // ── Cabecera con back ─────────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Empieza a registrar tu progreso hoy',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 14),
                ),

                const SizedBox(height: 36),

                // ── Campos ────────────────────────────────────────────────
                CustomTextField(
                  controller: _nameCtrl,
                  label: 'Nombre',
                  textInputAction: TextInputAction.next,
                  focusNode: _nameFocus,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(_emailFocus),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Introduce tu email';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordCtrl,
                  label: 'Contraseña',
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  focusNode: _passwordFocus,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(_confirmFocus),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Introduce una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmCtrl,
                  label: 'Confirmar contraseña',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  focusNode: _confirmFocus,
                  onEditingComplete: _register,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                    if (v != _passwordCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Error banner ──────────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  AuthErrorBanner(message: auth.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // ── Botón principal ───────────────────────────────────────
                PrimaryButton(
                  label: 'Crear cuenta',
                  onPressed: _register,
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

                // ── Ya tengo cuenta ───────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Inicia sesión',
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
}
