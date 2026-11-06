import 'package:flutter/material.dart';

import '../repositories/cuenta_repository.dart';
import '../repositories/cuenta_repository_mock.dart';
import '../repositories/cuenta_repository_supabase.dart';
import '../services/supabase_service.dart';
import '../state/perfil_local_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validacion_cuenta.dart';
import '../widgets/indicador_pasos.dart';
import '../widgets/mensaje_error.dart';

/// Entrar con correo y contraseña (ej. en otro dispositivo). Reemplaza la
/// sesión de invitado de este teléfono por la de la cuenta; Supabase Auth
/// valida las credenciales, la app nunca ve la contraseña guardada.
/// Devuelve true al entrar.
class IniciarSesionScreen extends StatefulWidget {
  final CuentaRepository? repositorio;

  const IniciarSesionScreen({super.key, this.repositorio});

  @override
  State<IniciarSesionScreen> createState() => _IniciarSesionScreenState();
}

class _IniciarSesionScreenState extends State<IniciarSesionScreen> {
  late final CuentaRepository _repo =
      widget.repositorio ??
      (SupabaseService.disponible
          ? CuentaRepositorySupabase()
          : CuentaRepositoryMock());

  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocupado = false;
  bool _verContrasena = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!formatoCorreoValido(_correo.text) || _contrasena.text.isEmpty) {
      setState(() => _error = 'Ingresa tu correo y tu contraseña.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final usuario = UsuarioScope.of(context);
    final perfilLocal = PerfilLocalScope.of(context);
    try {
      final authUserId = await _repo.iniciarSesion(
        _correo.text,
        _contrasena.text,
      );
      await usuario.cargar();
      await perfilLocal.cambiarClave(
        authUserId,
        nombreInicial: usuario.usuario?.alias,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on CuentaException catch (e) {
      debugPrint('IniciarSesion: $e');
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const Text(
                'Entra a tu cuenta',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                'Usa el correo y la contraseña con que creaste tu cuenta. '
                'Tus puntos y tu actividad vienen con ella.',
                style: TextStyle(color: colores.textoSecundario, fontSize: 15),
              ),
              if ((UsuarioScope.of(context).usuario?.esInvitado ?? false) &&
                  UsuarioScope.of(context).usuario!.puntosTotales > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Los puntos de tu sesión de invitado en este teléfono no se '
                  'suman a esa cuenta.',
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contrasena,
                obscureText: !_verContrasena,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _ocupado ? null : _entrar(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _verContrasena ? 'Ocultar' : 'Mostrar',
                    icon: Icon(
                      _verContrasena ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _verContrasena = !_verContrasena),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                MensajeError(texto: _error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _ocupado ? null : _entrar,
                child: TextoBoton(texto: 'Entrar', ocupado: _ocupado),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
