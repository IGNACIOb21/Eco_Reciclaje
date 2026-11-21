import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../repositories/acciones_por_defecto.dart';
import '../repositories/acciones_repository.dart';
import '../repositories/gamificacion_repository.dart';
import '../repositories/puntos_repository.dart';
import '../repositories/puntos_repository_mock.dart';
import '../repositories/puntos_repository_supabase.dart';
import '../services/camara_service.dart';
import '../services/permisos_service.dart';
import '../services/supabase_service.dart';
import '../state/primer_inicio_controller.dart';
import '../state/usuario_controller.dart';
import '../utils/rutas.dart';
import '../utils/snackbars.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/saldo_flotante.dart';
import '../widgets/resumen_inicio.dart';
import 'celebracion_nivel_screen.dart';
import 'comunidad_screen.dart';
import 'escanear_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';
import 'realizar_reporte_screen.dart';
import 'servicios_screen.dart';

/// Contenedor con la barra inferior de 5 lugares: Inicio (el mapa), Comunidad,
/// el botón redondo de Escanear al centro, Servicios y Perfil.
///
/// Escanear abre el escáner con el modelo de Joaquín; desde ahí, "Ver dónde
/// reciclarlo" vuelve a Inicio con el mapa filtrado por ese material.
class MainShell extends StatefulWidget {
  // Solo para tests: inyecta un repositorio (ej. mock) en vez del Supabase
  // real que usa MapaScreen por defecto.
  final PuntosRepository? puntosRepository;

  // Solo para tests: la meta y la racha de Hoy sin Supabase.
  final GamificacionRepository? gamificacionRepository;

  const MainShell({
    super.key,
    this.puntosRepository,
    this.gamificacionRepository,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with RouteAware {
  static const _inicio = 0;
  static const _perfil = 3;

  int _indice = _inicio;

  // Avisa a Hoy (Inicio) que vuelva a leer la meta y la racha.
  final _recargaHoy = ValueNotifier<int>(0);

  // Materiales que Escanear pide mostrar en el mapa.
  final _materialesPedidos = ValueNotifier<Set<TipoMaterial>>(const {});

  // Pestañas ya abiertas. Las demás no se construyen hasta la primera visita:
  // así Comunidad, Servicios y Perfil no consultan la base si nunca se abren.
  final _visitadas = <int>{_inicio};

  // Para celebrar una subida de nivel cuando el MainShell está a la vista.
  UsuarioController? _usuario;
  bool _celebrando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruta = ModalRoute.of(context);
    if (ruta != null) observadorRutas.subscribe(this, ruta);
    final usuario = context
        .getInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    if (usuario != _usuario) {
      _usuario?.removeListener(_quizasCelebrar);
      _usuario = usuario?..addListener(_quizasCelebrar);
    }
  }

  @override
  void dispose() {
    observadorRutas.unsubscribe(this);
    _usuario?.removeListener(_quizasCelebrar);
    _recargaHoy.dispose();
    _materialesPedidos.dispose();
    super.dispose();
  }

  /// Se cerró la pantalla que estaba encima (Reciclar, Retos, Para
  /// reclamar…): si mientras tanto se subió de nivel, se celebra ahora.
  @override
  void didPopNext() => _quizasCelebrar();

  /// Muestra la celebración si hay un nivel nuevo y el MainShell es la
  /// pantalla visible; si no, queda pendiente hasta que vuelva a serlo.
  void _quizasCelebrar() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final usuario = _usuario;
      final nivel = usuario?.nivelPorCelebrar;
      final resumen = usuario?.resumen;
      if (!mounted || _celebrando || nivel == null || resumen == null) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
      _celebrando = true;
      usuario!.celebracionMostrada();
      await mostrarCelebracionNivel(
        context,
        nivel: nivel,
        niveles: resumen.niveles,
        acumulado: resumen.acumulado,
      );
      _celebrando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pedirUbicacionLaPrimeraVez();
      _recuperarFoto();
    });
  }

  /// Respaldo: los permisos se muestran en la bienvenida. Si por algún motivo
  /// nunca se mostraron, el de ubicación se pide una sola vez sobre el mapa.
  /// Después se activa desde Perfil › Ajustes. Al volver del diálogo el mapa
  /// retoma el GPS solo (ver MapaScreen.didChangeAppLifecycleState).
  Future<void> _pedirUbicacionLaPrimeraVez() async {
    final primerInicio = context
        .getInheritedWidgetOfExactType<PrimerInicioScope>()
        ?.notifier;
    if (primerInicio == null || primerInicio.permisosSolicitados) return;
    await primerInicio.marcarPermisosSolicitados();
    if (!primerInicio.completado) await primerInicio.completar();
    await const PermisosService().pedir(PermisoApp.ubicacion);
  }

  /// Si Android cerró la app con la cámara abierta en un reporte, al volver
  /// abre "Realizar reporte" con la foto ya tomada. Si la foto no se puede
  /// procesar, solo avisa (la original ya se borró).
  Future<void> _recuperarFoto() async {
    final FotoRecuperada? recuperada;
    try {
      recuperada = await CamaraService().recuperarFotoPerdida();
    } on FotoNoProcesadaException catch (e) {
      if (mounted) mostrarSnackbar(context, e.mensaje);
      return;
    }
    if (recuperada == null) return;
    if (!mounted) {
      await CamaraService.borrar(recuperada.foto);
      return;
    }
    final pantalla = RealizarReporteScreen.desdePendiente(
      recuperada.pendiente,
      recuperada.foto,
      accionesPorDefecto(),
    );
    if (pantalla == null) {
      await CamaraService.borrar(recuperada.foto);
      return;
    }
    final usuario = context
        .getInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    final resultado = await Navigator.of(context)
        .push<Object>(MaterialPageRoute(builder: (_) => pantalla));
    if (resultado is! ResultadoAccion || !mounted) return;
    mostrarSnackbar(
      context,
      resultado.puntos > 0
          ? 'Gracias por avisar. +${resultado.puntos} puntos'
          : 'Gracias por avisar.',
    );
    usuario?.cargar();
  }

  void _irA(int indice) {
    setState(() {
      _indice = indice;
      _visitadas.add(indice);
    });
    // Inicio y Perfil muestran Rebin Points y nivel: se actualizan al entrar,
    // por si cambiaron en el servidor (un canje cancelado, un reporte revertido).
    if (indice == _inicio || indice == _perfil) {
      context
          .getInheritedWidgetOfExactType<UsuarioScope>()
          ?.notifier
          ?.cargarSiHaceFalta();
    }
    if (indice == _inicio) _recargaHoy.value++;
  }

  // Sin Supabase configurado (demo), el mapa usa el repositorio mock.
  PuntosRepository _puntos() =>
      widget.puntosRepository ??
      (SupabaseService.disponible
          ? PuntosRepositorySupabase()
          : PuntosRepositoryMock());

  /// Botón central de la barra: abre el escáner con el modelo de Joaquín.
  Future<void> _abrirEscanear() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pantalla) => EscanearScreen(
          onVerEnMapa: (material) {
            Navigator.of(pantalla).pop();
            _materialesPedidos.value = material == null ? const {} : {material};
            _irA(_inicio);
          },
        ),
      ),
    );
    // Registrar un reciclaje pudo cumplir la meta o sumar un día a la racha.
    if (mounted) _recargaHoy.value++;
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      // Inicio es el mapa de Ignacio (buscador, chips, lista y filtros); el
      // saludo, los Rebin Points y el nivel van en la cabecera de su lista.
      // Se apaga el GPS cuando no es la pestaña visible.
      MapaScreen(
        repositorio: _puntos(),
        activo: _indice == _inicio,
        materialesPedidos: _materialesPedidos,
        // El saldo va junto al buscador; tocarlo abre el Perfil.
        junto: SaldoFlotante(onTap: () => _irA(_perfil)),
        cabecera: ResumenInicio(
          gamificacion: widget.gamificacionRepository,
          recarga: _recargaHoy,
        ),
      ),
      const ComunidadScreen(),
      const ServiciosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      // El contenido (el mapa) sigue por detrás de la barra: alrededor de la
      // píldora no queda un rectángulo del color de fondo, solo se ve ella.
      extendBody: true,
      body: IndexedStack(
        index: _indice,
        children: [
          for (var i = 0; i < pantallas.length; i++)
            _visitadas.contains(i) ? pantallas[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BarraNavegacion(
        indice: _indice,
        onSeleccion: _irA,
        onEscanear: _abrirEscanear,
        destinos: const [
          DestinoBarra(
            icono: Icons.home_outlined,
            iconoActivo: Icons.home,
            etiqueta: 'Inicio',
          ),
          DestinoBarra(
            icono: Icons.groups_outlined,
            iconoActivo: Icons.groups,
            etiqueta: 'Comunidad',
          ),
          DestinoBarra(
            icono: Icons.miscellaneous_services_outlined,
            iconoActivo: Icons.miscellaneous_services,
            etiqueta: 'Servicios',
          ),
          DestinoBarra(
            icono: Icons.person_outline,
            iconoActivo: Icons.person,
            etiqueta: 'Perfil',
          ),
        ],
      ),
    );
  }
}
