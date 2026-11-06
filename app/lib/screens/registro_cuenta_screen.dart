import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/cuenta_repository.dart';
import '../repositories/cuenta_repository_mock.dart';
import '../repositories/cuenta_repository_supabase.dart';
import '../services/correo_service.dart';
import '../services/supabase_service.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../utils/validacion_cuenta.dart';
import '../widgets/indicador_pasos.dart';
import '../widgets/mensaje_error.dart';

/// Vincula la sesión anónima a un correo en 3 pasos: correo (formato y
/// dominio que recibe correo), código de 8 dígitos enviado a ese correo, y
/// contraseña para entrar desde otro dispositivo. Devuelve true al terminar.
class RegistroCuentaScreen extends StatefulWidget {
  final CuentaRepository? repositorio;

  /// Consulta de dominio inyectable para tests; por defecto DNS real.
  final Future<bool?> Function(String dominio) verificarDominio;

  /// 2 para retomar en la contraseña un registro con correo ya verificado.
  final int pasoInicial;

  const RegistroCuentaScreen({
    super.key,
    this.repositorio,
    this.verificarDominio = dominioRecibeCorreo,
    this.pasoInicial = 0,
  });

  @override
  State<RegistroCuentaScreen> createState() => _RegistroCuentaScreenState();
}

class _RegistroCuentaScreenState extends State<RegistroCuentaScreen> {
  late final CuentaRepository _repo =
      widget.repositorio ??
      (SupabaseService.disponible
          ? CuentaRepositorySupabase()
          : CuentaRepositoryMock());

  late int _paso = widget.pasoInicial;
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();

  bool _ocupado = false;
  String? _error;
  bool _verContrasena = false;

  // Supabase permite un correo cada 60 s por usuario.
  static const _esperaReenvio = 60;
  int _segundosReenvio = 0;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    _contrasena.addListener(() => setState(() {}));
    _confirmacion.addListener(() => setState(() {}));
    _codigo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _correo.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await accion();
    } on CuentaException catch (e) {
      debugPrint('Registro: $e');
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _iniciarEsperaReenvio() {
    _temporizador?.cancel();
    setState(() => _segundosReenvio = _esperaReenvio);
    _temporizador = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _segundosReenvio--);
      if (_segundosReenvio <= 0) t.cancel();
    });
  }

  // Paso 1: correo -----------------------------------------------------------

  Future<void> _enviarCodigo() => _ejecutar(() async {
    final correo = _correo.text.trim();
    if (!formatoCorreoValido(correo)) {
      setState(() => _error = 'Ese no parece un correo válido.');
      return;
    }
    // null = no se pudo consultar: no se bloquea, el código decide.
    if (await widget.verificarDominio(dominioDe(correo)) == false) {
      setState(
        () => _error =
            'El dominio "${dominioDe(correo)}" no existe o no recibe '
            'correos. Revisa que esté bien escrito.',
      );
      return;
    }
    await _repo.enviarCodigo(correo);
    _codigo.clear();
    _iniciarEsperaReenvio();
    setState(() => _paso = 1);
  });

  // Paso 2: código -----------------------------------------------------------

  Future<void> _verificarCodigo() => _ejecutar(() async {
    await _repo.verificarCodigo(_correo.text, _codigo.text);
    setState(() => _paso = 2);
  });

  Future<void> _reenviar() => _ejecutar(() async {
    await _repo.reenviarCodigo(_correo.text);
    _iniciarEsperaReenvio();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un código nuevo')),
      );
    }
  });

  // Paso 3: contraseña -------------------------------------------------------

  bool get _contrasenaLista =>
      contrasenaValida(_contrasena.text) &&
      _contrasena.text == _confirmacion.text;

  Future<void> _crearCuenta() => _ejecutar(() async {
    await _repo.crearContrasena(_contrasena.text);
    if (!mounted) return;
    // Recarga correo y estado del registro desde Supabase.
    await UsuarioScope.of(context).cargar();
    if (mounted) Navigator.of(context).pop(true);
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _paso != 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso == 1) {
          setState(() {
            _paso = 0;
            _error = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Crear cuenta')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              IndicadorPasos(paso: _paso, total: 3),
              const SizedBox(height: 24),
              ...switch (_paso) {
                0 => _pasoCorreo(context),
                1 => _pasoCodigo(context),
                _ => _pasoContrasena(context),
              },
              if (_error != null) ...[
                const SizedBox(height: 16),
                MensajeError(texto: _error!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _pasoCorreo(BuildContext context) {
    final colores = context.colores;
    return [
      const _Titulo('¿Cuál es tu correo?'),
      const SizedBox(height: 6),
      Text(
        'Tu cuenta de invitado, con tus puntos y tu actividad, quedará '
        'vinculada a este correo.',
        style: TextStyle(color: colores.textoSecundario, fontSize: 15),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _correo,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _ocupado ? null : _enviarCodigo(),
        decoration: const InputDecoration(
          labelText: 'Correo electrónico',
          hintText: 'nombre@ejemplo.com',
        ),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _ocupado ? null : _enviarCodigo,
        child: TextoBoton(texto: 'Enviar código', ocupado: _ocupado),
      ),
    ];
  }

  List<Widget> _pasoCodigo(BuildContext context) {
    final colores = context.colores;
    return [
      const _Titulo('Revisa tu correo'),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          text: 'Enviamos un código de 8 dígitos a ',
          children: [
            TextSpan(
              text: _correo.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '. Si no lo ves, revisa la carpeta de spam.'),
          ],
        ),
        style: TextStyle(color: colores.textoSecundario, fontSize: 15),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _codigo,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(hintText: '••••••••'),
        onSubmitted: (_) =>
            _codigo.text.length == 8 && !_ocupado ? _verificarCodigo() : null,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _codigo.text.length == 8 && !_ocupado
            ? _verificarCodigo
            : null,
        child: TextoBoton(texto: 'Verificar', ocupado: _ocupado),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _ocupado
                ? null
                : () => setState(() {
                    _paso = 0;
                    _error = null;
                  }),
            child: const Text('Cambiar correo'),
          ),
          TextButton(
            onPressed: _ocupado || _segundosReenvio > 0 ? null : _reenviar,
            child: Text(
              _segundosReenvio > 0
                  ? 'Reenviar en $_segundosReenvio s'
                  : 'Reenviar código',
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _pasoContrasena(BuildContext context) {
    final colores = context.colores;
    final texto = _contrasena.text;
    final conEspacios = !contrasenaSinEspacios(texto);
    final noCoincide =
        _confirmacion.text.isNotEmpty && _confirmacion.text != texto;
    return [
      const _Titulo('Crea tu contraseña'),
      const SizedBox(height: 6),
      Text(
        'La usarás para entrar a tu cuenta desde otro dispositivo.',
        style: TextStyle(color: colores.textoSecundario, fontSize: 15),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _contrasena,
        obscureText: !_verContrasena,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.newPassword],
        decoration: InputDecoration(
          labelText: 'Contraseña',
          errorText: conEspacios ? 'No puede tener espacios' : null,
          suffixIcon: IconButton(
            tooltip: _verContrasena ? 'Ocultar' : 'Mostrar',
            icon: Icon(
              _verContrasena ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () => setState(() => _verContrasena = !_verContrasena),
          ),
        ),
      ),
      const SizedBox(height: 12),
      for (final regla in reglasContrasena)
        _ReglaFila(texto: regla.texto, cumple: regla.cumple(texto)),
      const SizedBox(height: 16),
      TextField(
        controller: _confirmacion,
        obscureText: !_verContrasena,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: 'Repite la contraseña',
          errorText: noCoincide ? 'Las contraseñas no coinciden' : null,
        ),
        onSubmitted: (_) =>
            _contrasenaLista && !_ocupado ? _crearCuenta() : null,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _contrasenaLista && !_ocupado ? _crearCuenta : null,
        child: TextoBoton(texto: 'Crear cuenta', ocupado: _ocupado),
      ),
    ];
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
    );
  }
}

class _ReglaFila extends StatelessWidget {
  final String texto;
  final bool cumple;

  const _ReglaFila({required this.texto, required this.cumple});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: cumple ? colores.primario : colores.textoSecundario,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              color: cumple ? colores.texto : colores.textoSecundario,
              fontWeight: cumple ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
