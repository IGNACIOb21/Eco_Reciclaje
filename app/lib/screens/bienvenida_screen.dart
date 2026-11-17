import 'package:flutter/material.dart';

import '../repositories/cuenta_repository.dart';
import '../services/permisos_service.dart';
import '../state/perfil_local_controller.dart';
import '../state/primer_inicio_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/indicador_pasos.dart';
import 'iniciar_sesion_screen.dart';

/// Primer inicio tras instalar la app, en dos pantallas:
/// 1. Acceso: "Regístrate" / "Inicia sesión", con "Omitir" arriba para
///    seguir como invitado.
/// 2. Datos y permisos: nombre de usuario (obligatorio; se salta si se inició
///    sesión con una cuenta que ya lo tiene) y los permisos de ubicación,
///    cámara y notificaciones, todos opcionales (quedan en Perfil › Ajustes).
/// Al terminar marca el primer inicio como completado y la app entra al
/// MainShell; no se vuelve a pasar por aquí, ni al cerrar o iniciar sesión.
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

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alias = TextEditingController();

  /// null mientras se está en el acceso; luego indica si se pide el alias.
  bool? _pedirAlias;
  bool _guardando = false;

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  void _salirDelAcceso({required bool pedirAlias}) {
    // Los permisos se marcan como mostrados al entrar: aunque la app se
    // cierre a mitad de camino, el mapa no los vuelve a pedir solo.
    PrimerInicioScope.of(context).marcarPermisosSolicitados();
    setState(() => _pedirAlias = pedirAlias);
  }

  Future<void> _empezar() async {
    final primerInicio = PrimerInicioScope.of(context);
    if (_pedirAlias == true) {
      if (!_formKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      setState(() => _guardando = true);
      final alias = _alias.text.trim();
      final perfilLocal = PerfilLocalScope.of(context);
      final usuario = UsuarioScope.of(context);
      // El alias se guarda primero en el teléfono (saludo de Inicio, Perfil):
      // así el invitado no depende de la red. En Supabase se guarda si se
      // puede; si falla, la app sigue con el alias local.
      await perfilLocal.actualizar(perfilLocal.perfil.copyWith(nombre: alias));
      try {
        await usuario.guardarDatos(alias: alias);
      } catch (e) {
        debugPrint('Bienvenida: no se pudo guardar el alias remoto ($e)');
      }
      if (!mounted) return;
      setState(() => _guardando = false);
    }
    await primerInicio.completar();
  }

  @override
  Widget build(BuildContext context) {
    final pedirAlias = _pedirAlias;
    if (pedirAlias == null) {
      return IniciarSesionScreen(
        repositorio: widget.cuentaRepositorio,
        onOmitir: () => _salirDelAcceso(pedirAlias: true),
        onListo: (resultado) => _salirDelAcceso(
          pedirAlias: resultado == ResultadoAcceso.cuentaCreada,
        ),
      );
    }

    final colores = context.colores;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _pedirAlias = null);
      },
      child: Scaffold(
        backgroundColor: colores.fondo,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                Icon(Icons.recycling, size: 48, color: colores.primario),
                const SizedBox(height: 16),
                const Text(
                  '¡Bienvenido a Eco Reciclaje!',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
                ),
                if (pedirAlias) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Elige cómo te verán los demás.',
                    style: TextStyle(
                      color: colores.textoSecundario,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _CampoAlias(
                    controller: _alias,
                    onEnviar: _guardando ? null : _empezar,
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  'Permisos',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Son opcionales. Puedes cambiarlos cuando quieras en '
                  'Perfil › Ajustes.',
                  style: TextStyle(color: colores.textoSecundario, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _FilaPermiso(
                  key: const ValueKey('permiso-ubicacion'),
                  permisos: widget.permisos,
                  permiso: PermisoApp.ubicacion,
                  icono: Icons.map_outlined,
                  titulo: 'Ubicación',
                  texto: 'Para mostrarte en el mapa los puntos de reciclaje '
                      'más cercanos.',
                ),
                _FilaPermiso(
                  key: const ValueKey('permiso-camara'),
                  permisos: widget.permisos,
                  permiso: PermisoApp.camara,
                  icono: Icons.photo_camera_outlined,
                  titulo: 'Cámara',
                  texto: 'Para escanear tus residuos y saber de qué material '
                      'son.',
                ),
                _FilaPermiso(
                  key: const ValueKey('permiso-notificaciones'),
                  permisos: widget.permisos,
                  permiso: PermisoApp.notificaciones,
                  icono: Icons.notifications_active_outlined,
                  titulo: 'Notificaciones',
                  texto: 'Para avisarte de novedades de tu comunidad y cuando '
                      'subas de nivel.',
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _guardando ? null : _empezar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                  ),
                  child: TextoBoton(texto: 'Empezar', ocupado: _guardando),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoAlias extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onEnviar;

  const _CampoAlias({required this.controller, required this.onEnviar});

  static final _aliasValido = RegExp(r'^[A-Za-z0-9_.]+$');

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 30,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onEnviar?.call(),
      decoration: const InputDecoration(
        labelText: 'Nombre de usuario',
        hintText: 'Ej. cami_recicla',
        helperText: 'Obligatorio. Así te verán en la comunidad.',
        counterText: '',
      ),
      validator: (valor) {
        final v = valor?.trim() ?? '';
        if (v.isEmpty) return 'Elige un nombre de usuario';
        // La base exige entre 3 y 30 caracteres (app_guardar_alias).
        if (v.length < 3) return 'Debe tener al menos 3 caracteres';
        if (!_aliasValido.hasMatch(v)) {
          return 'Solo letras, números, punto y guion bajo';
        }
        return null;
      },
    );
  }
}

/// Un permiso opcional: explica para qué sirve y muestra "Permitir" o, si ya
/// está concedido, un check. Si Android lo bloqueó (dos rechazos), el botón
/// abre los ajustes del teléfono.
class _FilaPermiso extends StatefulWidget {
  final PermisosService permisos;
  final PermisoApp permiso;
  final IconData icono;
  final String titulo;
  final String texto;

  const _FilaPermiso({
    super.key,
    required this.permisos,
    required this.permiso,
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  @override
  State<_FilaPermiso> createState() => _FilaPermisoState();
}

class _FilaPermisoState extends State<_FilaPermiso> {
  EstadoPermiso? _estado;
  bool _pidiendo = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final concedido = _estado == EstadoPermiso.concedido;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colores.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colores.primario.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icono, color: colores.primario),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.texto,
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (concedido)
            Icon(
              Icons.check_circle,
              color: colores.primario,
              semanticLabel: 'Permitido',
            )
          else
            TextButton(
              onPressed: _pidiendo ? null : _pedir,
              child: Text(
                _estado == EstadoPermiso.bloqueado ? 'Ajustes' : 'Permitir',
              ),
            ),
        ],
      ),
    );
  }
}
