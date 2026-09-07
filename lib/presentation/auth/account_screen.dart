import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pantalla "¿Estás registrado?" — login / registro con cuenta Supabase.
///
/// Se muestra cuando no hay sesión remota activa. Tras autenticar,
/// AuthGate pasa a PIN (primera vez) o a LockScreen.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Ingresa un correo válido.');
      return;
    }
    if (pass.length < 6) {
      setState(
          () => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    final ctrl = ref.read(authControllerProvider);
    setState(() {
      _busy = true;
      _error = null;
    });

    final errorMsg = _isRegister
        ? await ctrl.signUpRemote(email: email, password: pass)
        : await ctrl.signInRemote(email: email, password: pass);

    if (!mounted) return;
    setState(() {
      _busy = false;
      if (errorMsg != null) _error = errorMsg;
    });
    // Si OK: AuthGate reacciona al cambio de estado y muestra el PIN/dashboard.
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

@override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.goalGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.account_circle_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  _isRegister ? 'Crear tu cuenta' : 'Bienvenido de nuevo',
                  textAlign: TextAlign.center,
                  style: text.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegister
                      ? 'Un solo registro para tu teléfono y tu web'
                      : 'Inicia sesión para recuperar tu progreso',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'correo@ejemplo.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: text.bodySmall?.copyWith(color: AppColors.coral)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isRegister ? 'Registrarme' : 'Iniciar sesión',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _isRegister = !_isRegister;
                            _error = null;
                          });
                        },
                  child: Text(
                    _isRegister
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿Eres nuevo? Crea tu cuenta',
                    style: const TextStyle(color: AppColors.cyan),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La cuenta sincroniza tus datos entre dispositivos.',
                  textAlign: TextAlign.center,
                  style:
                      text.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}