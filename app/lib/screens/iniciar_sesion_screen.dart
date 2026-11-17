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
import 'registro_cuenta_screen.dart';

/// Tarjeta de acceso con dos pestañas: "Regístrate" (vincula la sesión de
/// invitado a un correo, ver RegistroCuentaScreen) e "Inicia sesión" (entra
/// con correo y contraseña; Supabase Auth valida que el correo exista y que
/// la contraseña sea la correcta, la app nunca ve la contraseña guardada).
///
/// Abierta como ruta devuelve, al cerrarse, el mensaje para mostrar ('Sesión
/// iniciada' o el de cuenta creada), o null si se cerró sin hacer nada.
///
/// En el primer inicio (BienvenidaScreen) es la pantalla de entrada: en vez
/// de la X muestra "Omitir" y avisa con [onListo] en lugar de cerrarse.
class IniciarSesionScreen extends StatefulWidget {
  final CuentaRepository? repositorio;

  /// Abre directo en la pestaña "Regístrate".
  final bool enRegistro;

  /// Si no es null, muestra el botón "Omitir" arriba a la izquierda (seguir
  /// como invitado) en lugar de la X.
  final VoidCallback? onOmitir;

  /// Si no es null, se llama al iniciar sesión o crear la cuenta en vez de
  /// cerrar la pantalla.
  final ValueChanged<ResultadoAcceso>? onListo;

  const IniciarSesionScreen({
    super.key,
    this.repositorio,
    this.enRegistro = false,
    this.onOmitir,
    this.onListo,
  });

  @override
  State<IniciarSesionScreen> createState() => _IniciarSesionScreenState();
}

enum ResultadoAcceso {
  sesionIniciada('Sesión iniciada'),
  cuentaCreada('¡Listo! Tu cuenta quedó creada');

  final String mensaje;
  const ResultadoAcceso(this.mensaje);
}

class _IniciarSesionScreenState extends State<IniciarSesionScreen> {
  late final CuentaRepository _repo =
      widget.repositorio ??
      (SupabaseService.disponible
          ? CuentaRepositorySupabase()
          : CuentaRepositoryMock());

  late bool _enRegistro = widget.enRegistro;
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
      if (mounted) _terminar(ResultadoAcceso.sesionIniciada);
    } on CuentaException catch (e) {
      debugPrint('IniciarSesion: $e');
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _crearCuenta() async {
    final listo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegistroCuentaScreen(repositorio: widget.repositorio),
      ),
    );
    if (listo == true && mounted) _terminar(ResultadoAcceso.cuentaCreada);
  }

  void _terminar(ResultadoAcceso resultado) {
    final onListo = widget.onListo;
    if (onListo != null) {
      onListo(resultado);
    } else {
      Navigator.of(context).pop(resultado.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      backgroundColor: colores.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onOmitir != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _BotonOmitir(onPressed: widget.onOmitir!),
              ),
            Expanded(child: _tarjeta(colores)),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(ColoresApp colores) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            decoration: BoxDecoration(
              color: colores.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colores.borde),
            ),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onOmitir == null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Cerrar',
                        icon: Icon(Icons.close, color: colores.textoSecundario),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                  // FittedBox: con letra grande (accesibilidad) las
                  // pestañas se achican en vez de desbordarse.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        _Pestana(
                          texto: 'Regístrate',
                          activa: _enRegistro,
                          onTap: () => setState(() {
                            _enRegistro = true;
                            _error = null;
                          }),
                        ),
                        const SizedBox(width: 28),
                        _Pestana(
                          texto: 'Inicia sesión',
                          activa: !_enRegistro,
                          onTap: () => setState(() => _enRegistro = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_enRegistro)
                    _ContenidoRegistro(
                      yaTieneCorreo: _repo.tieneCorreoVinculado,
                      onCrearCuenta: _crearCuenta,
                    )
                  else
                    ..._contenidoInicioSesion(colores),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenidoInicioSesion(ColoresApp colores) {
    final usuario = UsuarioScope.of(context).usuario;
    return [
      TextField(
        controller: _correo,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.next,
        decoration: _decoracion(colores, 'Correo electrónico'),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _contrasena,
        obscureText: !_verContrasena,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.password],
        onSubmitted: (_) => _ocupado ? null : _entrar(),
        decoration: _decoracion(colores, 'Contraseña').copyWith(
          suffixIcon: IconButton(
            tooltip: _verContrasena ? 'Ocultar' : 'Mostrar',
            icon: Icon(
              _verContrasena ? Icons.visibility : Icons.visibility_off,
              color: colores.textoSecundario,
            ),
            onPressed: () => setState(() => _verContrasena = !_verContrasena),
          ),
        ),
      ),
      if ((usuario?.esInvitado ?? false) && usuario!.puntosTotales > 0) ...[
        const SizedBox(height: 12),
        Text(
          'Los Rebin Points de tu sesión de invitado en este teléfono no se suman '
          'a esa cuenta.',
          style: TextStyle(color: colores.textoSecundario, fontSize: 13),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 16),
        MensajeError(texto: _error!),
      ],
      const SizedBox(height: 24),
      _BotonPildora(
        onPressed: _ocupado ? null : _entrar,
        child: TextoBoton(texto: 'Iniciar sesión', ocupado: _ocupado),
      ),
    ];
  }

  InputDecoration _decoracion(ColoresApp colores, String sugerencia) {
    OutlineInputBorder borde(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      hintText: sugerencia,
      filled: true,
      fillColor: colores.fondo,
      enabledBorder: borde(colores.borde),
      focusedBorder: borde(colores.primario),
      border: borde(colores.borde),
    );
  }
}

/// Pestaña de texto con barra inferior cuando está activa.
class _Pestana extends StatelessWidget {
  final String texto;
  final bool activa;
  final VoidCallback onTap;

  const _Pestana({
    required this.texto,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              style: TextStyle(
                fontSize: 17,
                fontWeight: activa ? FontWeight.w800 : FontWeight.w500,
                color: activa ? colores.texto : colores.textoSecundario,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: activa ? 36 : 0,
              decoration: BoxDecoration(
                color: colores.primario,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoRegistro extends StatelessWidget {
  final bool yaTieneCorreo;
  final VoidCallback onCrearCuenta;

  const _ContenidoRegistro({
    required this.yaTieneCorreo,
    required this.onCrearCuenta,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    if (yaTieneCorreo) {
      return Text(
        'Esta sesión ya tiene una cuenta con correo. Para crear otra, '
        'primero cierra sesión desde tu Perfil.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colores.textoSecundario, fontSize: 15),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vincula un correo a tu cuenta para guardar tus Rebin Points y entrar '
          'desde otro dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colores.textoSecundario, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _BotonPildora(
          onPressed: onCrearCuenta,
          child: const Text('Crear cuenta'),
        ),
      ],
    );
  }
}

/// "Omitir" del primer inicio: casilla verde que ocupa un tercio del ancho,
/// arriba a la izquierda.
class _BotonOmitir extends StatelessWidget {
  final VoidCallback onPressed;

  const _BotonOmitir({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 1 / 3,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: colores.primario,
            foregroundColor: colores.sobrePrimario,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Omitir')),
        ),
      ),
    );
  }
}

/// Botón principal de ancho completo con bordes de cápsula.
class _BotonPildora extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _BotonPildora({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        backgroundColor: colores.primario,
        foregroundColor: colores.sobrePrimario,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: child,
    );
  }
}
