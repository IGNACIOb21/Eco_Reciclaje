import 'package:flutter/material.dart';

import '../services/permisos_service.dart';
import '../state/perfil_local_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/indicador_pasos.dart';
import 'iniciar_sesion_screen.dart';

/// Bienvenida obligatoria al iniciar sesión con una cuenta sin nombre: pide
/// nombre y alias (obligatorios) y luego los permisos de ubicación y
/// notificaciones. Los permisos se pueden rechazar; quedan disponibles en
/// Ajustes del Perfil. Al terminar guarda nombre y alias en Supabase, y con
/// eso `Usuario.faltanDatos` pasa a false y la app entra al MainShell.
class BienvenidaScreen extends StatefulWidget {
  final PermisosService permisos;

  const BienvenidaScreen({super.key, this.permisos = const PermisosService()});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _alias = TextEditingController();
  int _paso = 0;
  bool _guardando = false;
  String? _error;

  static const _totalPasos = 3;

  @override
  void dispose() {
    _nombre.dispose();
    _alias.dispose();
    super.dispose();
  }

  void _continuarDatos() {
    if (_formKey.currentState!.validate()) setState(() => _paso = 1);
  }

  Future<void> _terminar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    final alias = _alias.text.trim();
    final perfilLocal = PerfilLocalScope.of(context);
    try {
      // El alias es el nombre visible de la app (saludo de Inicio, Perfil).
      await perfilLocal.actualizar(perfilLocal.perfil.copyWith(nombre: alias));
      if (!mounted) return;
      await UsuarioScope.of(context)
          .guardarDatos(nombre: _nombre.text.trim(), alias: alias);
    } catch (e) {
      debugPrint('Bienvenida: no se pudieron guardar los datos ($e)');
      if (mounted) {
        setState(
          () => _error =
              'No pudimos guardar tus datos. Revisa tu conexión e '
              'inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return PopScope(
      canPop: _paso == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso > 0) setState(() => _paso--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IndicadorPasos(paso: _paso, total: _totalPasos),
                const SizedBox(height: 24),
                Expanded(
                  child: switch (_paso) {
                    0 => _PasoDatos(
                      formKey: _formKey,
                      nombre: _nombre,
                      alias: _alias,
                      onContinuar: _continuarDatos,
                    ),
                    1 => _PasoPermiso(
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
                      onSiguiente: () => setState(() => _paso = 2),
                    ),
                    _ => _PasoPermiso(
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
                      ocupado: _guardando,
                      onSiguiente: _terminar,
                    ),
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colores.texto, fontSize: 13),
                  ),
                ],
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
  final VoidCallback onContinuar;

  const _PasoDatos({
    required this.formKey,
    required this.nombre,
    required this.alias,
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
            'Antes de empezar, cuéntanos quién eres.',
            style: TextStyle(color: colores.textoSecundario, fontSize: 15),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: nombre,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Camila Rojas',
              counterText: '',
            ),
            validator: (valor) {
              final v = valor?.trim() ?? '';
              if (v.isEmpty) return 'Ingresa tu nombre';
              if (v.length < 2) return 'Debe tener al menos 2 letras';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: alias,
            maxLength: 30,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onContinuar(),
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
          const SizedBox(height: 28),
          FilledButton(onPressed: onContinuar, child: const Text('Continuar')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IniciarSesionScreen()),
            ),
            child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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
  final bool ocupado;
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
    this.ocupado = false,
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
    final ocupado = widget.ocupado || _pidiendo;

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
