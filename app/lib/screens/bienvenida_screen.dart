import 'package:flutter/material.dart';

import '../models/perfil_local.dart';
import '../repositories/cuenta_repository.dart';
import '../services/permisos_service.dart';
import '../state/perfil_local_controller.dart';
import '../state/primer_inicio_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/indicador_pasos.dart';
import 'iniciar_sesion_screen.dart';
import 'onboarding_screen.dart';

/// Primer inicio tras instalar la app. Parte con las 3 láminas de
/// presentación (una sola vez; el avatar que se elige ahí queda en el perfil
/// local) y sigue en el acceso (registro / inicio de sesión) con "Omitir"
/// para seguir como invitado:
/// - Omitir o crear cuenta → alias (obligatorio) y nombre (opcional).
/// - Iniciar sesión → la cuenta ya tiene alias, se salta ese paso.
/// Luego, si nunca se le mostraron, los permisos de ubicación y
/// notificaciones (se pueden rechazar; quedan en Perfil › Ajustes). Al
/// terminar marca el primer inicio como completado y la app entra al MainShell
/// para no volver a pasar por aquí, ni al cerrar o iniciar sesión.
class BienvenidaScreen extends StatefulWidget {
  final PermisosService permisos;

  /// Solo para tests: se pasa a IniciarSesionScreen.
  final CuentaRepository? cuentaRepositorio;

  const BienvenidaScreen({
    super.key,
    this.permisos = const PermisosService(),
    this.cuentaRepositorio,
  });

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

enum _Paso { datos, ubicacion, notificaciones }

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _alias = TextEditingController();

  /// Pasos que quedan después del acceso; vacío mientras se está en él.
  List<_Paso> _pasos = const [];
  int _indice = 0;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _alias.dispose();
    super.dispose();
  }

  void _salirDelAcceso({required bool pedirDatos}) {
    final permisosPendientes = !PrimerInicioScope.of(context)
        .permisosSolicitados;
    final pasos = [
      if (pedirDatos) _Paso.datos,
      if (permisosPendientes) ...[_Paso.ubicacion, _Paso.notificaciones],
    ];
    if (pasos.isEmpty) {
      _terminar();
      return;
    }
    setState(() {
      _pasos = pasos;
      _indice = 0;
    });
    _alEntrarAPaso();
  }

  void _siguiente() {
    if (_indice + 1 >= _pasos.length) {
      _terminar();
      return;
    }
    setState(() => _indice++);
    _alEntrarAPaso();
  }

  /// Los permisos se marcan como solicitados apenas se muestran: aunque la
  /// app se cierre a mitad de camino, no se vuelven a pedir solos.
  void _alEntrarAPaso() {
    if (_pasos[_indice] == _Paso.ubicacion) {
      PrimerInicioScope.of(context).marcarPermisosSolicitados();
    }
  }

  void _atras() {
    setState(() {
      if (_indice > 0) {
        _indice--;
      } else {
        _pasos = const [];
      }
    });
  }

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    final alias = _alias.text.trim();
    final nombre = _nombre.text.trim();
    final perfilLocal = PerfilLocalScope.of(context);
    final usuario = UsuarioScope.of(context);
    // El alias es el nombre visible de la app (saludo de Inicio, Perfil) y se
    // guarda primero en el teléfono: el perfil de invitado no depende de la
    // red. En Supabase se guarda si se puede; si falla (sin conexión o sin
    // las policies RLS) la app sigue igual con el alias local.
    await perfilLocal.actualizar(perfilLocal.perfil.copyWith(nombre: alias));
    try {
      await usuario.guardarDatos(
        alias: alias,
        nombre: nombre.isEmpty ? null : nombre,
      );
    } catch (e) {
      debugPrint('Bienvenida: no se pudieron guardar los datos remotos ($e)');
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    _siguiente();
  }

  Future<void> _terminar() => PrimerInicioScope.of(context).completar();

  /// Guarda el avatar elegido en las láminas y pasa al acceso.
  Future<void> _terminarOnboarding(AvatarIcono icono, int color) async {
    final perfilLocal = PerfilLocalScope.of(context);
    final primerInicio = PrimerInicioScope.of(context);
    await perfilLocal.actualizar(
      perfilLocal.perfil.copyWith(avatarIcono: icono, avatarColorIndex: color),
    );
    await primerInicio.marcarOnboardingVisto();
  }

  @override
  Widget build(BuildContext context) {
    if (!PrimerInicioScope.of(context).onboardingVisto) {
      return OnboardingScreen(onTerminar: _terminarOnboarding);
    }
    if (_pasos.isEmpty) {
      return IniciarSesionScreen(
        repositorio: widget.cuentaRepositorio,
        onOmitir: () => _salirDelAcceso(pedirDatos: true),
        onListo: (resultado) => _salirDelAcceso(
          pedirDatos: resultado == ResultadoAcceso.cuentaCreada,
        ),
      );
    }

    final paso = _pasos[_indice];
    final ultimo = _indice == _pasos.length - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_pasos.length > 1) ...[
                  IndicadorPasos(paso: _indice, total: _pasos.length),
                  const SizedBox(height: 24),
                ],
                Expanded(
                  child: switch (paso) {
                    _Paso.datos => _PasoDatos(
                      formKey: _formKey,
                      nombre: _nombre,
                      alias: _alias,
                      ocupado: _guardando,
                      textoBoton: ultimo ? 'Empezar' : 'Continuar',
                      onContinuar: _guardarDatos,
                    ),
                    _Paso.ubicacion => _PasoPermiso(
                      key: const ValueKey('permiso-ubicacion'),
                      permisos: widget.permisos,
                      permiso: PermisoApp.ubicacion,
                      icono: Icons.my_location,
                      titulo: 'Activa tu ubicación',
                      texto:
                          'Rebin usa tu ubicación en tiempo real para '
                          'mostrarte los puntos de reciclaje más cercanos y '
                          'guiarte hasta ellos. Sin este permiso el mapa no '
                          'puede ubicarte.',
                      textoRechazo:
                          'Sin ubicación el mapa no sabrá dónde estás. '
                          'Puedes activarla cuando quieras en Perfil › '
                          'Ajustes.',
                      onSiguiente: _siguiente,
                    ),
                    _Paso.notificaciones => _PasoPermiso(
                      key: const ValueKey('permiso-notificaciones'),
                      permisos: widget.permisos,
                      permiso: PermisoApp.notificaciones,
                      icono: Icons.notifications_active_outlined,
                      titulo: 'Recibe avisos',
                      texto:
                          'Te avisaremos de eventos de reciclaje en tu '
                          'comuna, novedades de tu comunidad y cuando subas '
                          'de nivel.',
                      textoRechazo:
                          'No recibirás ninguna notificación. Puedes '
                          'activarlas cuando quieras en Perfil › Ajustes.',
                      textoFinal: 'Empezar',
                      onSiguiente: _siguiente,
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasoDatos extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombre;
  final TextEditingController alias;
  final bool ocupado;
  final String textoBoton;
  final VoidCallback onContinuar;

  const _PasoDatos({
    required this.formKey,
    required this.nombre,
    required this.alias,
    required this.ocupado,
    required this.textoBoton,
    required this.onContinuar,
  });

  static final _aliasValido = RegExp(r'^[A-Za-z0-9_.]+$');

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Form(
      key: formKey,
      child: ListView(
        children: [
          Icon(Icons.recycling, size: 48, color: colores.primario),
          const SizedBox(height: 16),
          const Text(
            '¡Bienvenido a Rebin!',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige cómo te verán los demás en Rebin.',
            style: TextStyle(color: colores.textoSecundario, fontSize: 15),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: alias,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Alias',
              hintText: 'Ej. cami_recicla',
              helperText: 'Así te verán los demás en Rebin',
              counterText: '',
            ),
            validator: (valor) {
              final v = valor?.trim() ?? '';
              if (v.isEmpty) return 'Elige un alias';
              if (v.length < 2) return 'Debe tener al menos 2 caracteres';
              if (!_aliasValido.hasMatch(v)) {
                return 'Solo letras, números, punto y guion bajo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nombre,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => ocupado ? null : onContinuar(),
            decoration: const InputDecoration(
              labelText: 'Nombre (opcional)',
              hintText: 'Ej. Camila Rojas',
              counterText: '',
            ),
            validator: (valor) {
              final v = valor?.trim() ?? '';
              if (v.isNotEmpty && v.length < 2) {
                return 'Debe tener al menos 2 letras';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: ocupado ? null : onContinuar,
            child: TextoBoton(texto: textoBoton, ocupado: ocupado),
          ),
        ],
      ),
    );
  }
}

class _PasoPermiso extends StatefulWidget {
  final PermisosService permisos;
  final PermisoApp permiso;
  final IconData icono;
  final String titulo;
  final String texto;
  final String textoRechazo;
  final String textoFinal;
  final VoidCallback onSiguiente;

  const _PasoPermiso({
    super.key,
    required this.permisos,
    required this.permiso,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.textoRechazo,
    required this.onSiguiente,
    this.textoFinal = 'Continuar',
  });

  @override
  State<_PasoPermiso> createState() => _PasoPermisoState();
}

class _PasoPermisoState extends State<_PasoPermiso> {
  EstadoPermiso? _estado;
  bool _pidiendo = false;
  bool _yaPedido = false;

  @override
  void initState() {
    super.initState();
    widget.permisos.estado(widget.permiso).then((e) {
      if (mounted) setState(() => _estado = e);
    });
  }

  Future<void> _pedir() async {
    setState(() => _pidiendo = true);
    final estado = await widget.permisos.pedir(widget.permiso);
    if (!mounted) return;
    setState(() {
      _estado = estado;
      _pidiendo = false;
      _yaPedido = true;
    });
    if (estado == EstadoPermiso.concedido) widget.onSiguiente();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final concedido = _estado == EstadoPermiso.concedido;
    // Si ya estaba bloqueado o se rechazó el diálogo, se explica qué implica
    // seguir sin el permiso.
    final rechazado =
        !concedido && (_yaPedido || _estado == EstadoPermiso.bloqueado);
    final ocupado = _pidiendo;

    return ListView(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colores.primario.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icono, size: 40, color: colores.primario),
        ),
        const SizedBox(height: 20),
        Text(
          widget.titulo,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          widget.texto,
          style: TextStyle(color: colores.textoSecundario, fontSize: 15),
        ),
        if (concedido) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle, color: colores.primario, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Permiso concedido',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ] else if (rechazado) ...[
          const SizedBox(height: 16),
          Text(
            widget.textoRechazo,
            style: TextStyle(color: colores.textoSecundario, fontSize: 13),
          ),
        ],
        const SizedBox(height: 28),
        if (concedido)
          FilledButton(
            onPressed: ocupado ? null : widget.onSiguiente,
            child: TextoBoton(texto: widget.textoFinal, ocupado: ocupado),
          )
        else ...[
          FilledButton(
            onPressed: ocupado ? null : _pedir,
            child: TextoBoton(
              texto: _estado == EstadoPermiso.bloqueado
                  ? 'Abrir ajustes del teléfono'
                  : 'Permitir',
              ocupado: ocupado,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: ocupado ? null : widget.onSiguiente,
            child: Text(
              widget.textoFinal == 'Continuar'
                  ? 'Ahora no'
                  : 'Ahora no, ${widget.textoFinal.toLowerCase()}',
            ),
          ),
        ],
      ],
    );
  }
}
