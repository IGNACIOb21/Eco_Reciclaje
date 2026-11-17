import 'package:flutter/material.dart';

import '../repositories/gamificacion_repository.dart';
import '../repositories/para_reclamar.dart';
import '../repositories/retos_repository.dart';
import '../services/haptica.dart';
import '../state/usuario_controller.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import '../utils/snackbars.dart';
import '../widgets/boton_app.dart';
import '../widgets/brillo_recompensa.dart';
import '../widgets/contador_puntos.dart';
import '../widgets/pill.dart';
import '../widgets/puntos_que_vuelan.dart';
import '../widgets/esqueleto.dart';

/// Todo lo que se puede cobrar ahora: niveles de logro, misiones listas y la
/// sorpresa de hoy; abajo, los niveles ya reclamados. Los Rebin Points los
/// acredita la base al reclamar; la app solo lo pide y recarga el saldo.
class ParaReclamarScreen extends StatefulWidget {
  final RetosRepository retos;
  final GamificacionRepository gamificacion;

  const ParaReclamarScreen({
    super.key,
    required this.retos,
    required this.gamificacion,
  });

  @override
  State<ParaReclamarScreen> createState() => _ParaReclamarScreenState();
}

class _ParaReclamarScreenState extends State<ParaReclamarScreen> {
  static const _romanos = ['I', 'II', 'III', 'IV', 'V'];

  late Future<ParaReclamar> _futuro = _leer();
  final _llaveSaldo = GlobalKey();
  String? _reclamando;

  /// Puntos de la sorpresa recién abierta, para mostrar "+3" en su tarjeta.
  int? _sorpresaGanada;

  Future<ParaReclamar> _leer() =>
      ParaReclamar.cargar(widget.retos, widget.gamificacion);

  void _recargar() => setState(() => _futuro = _leer());

  /// Reclama, hace volar los puntos hasta el saldo y vuelve a leer la lista.
  Future<void> _cobrar(
    String clave,
    GlobalKey origen,
    Future<int> Function() reclamar,
  ) async {
    final usuario = context
        .getInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    setState(() => _reclamando = clave);
    final int puntos;
    try {
      puntos = await reclamar();
    } on GamificacionException catch (e) {
      if (!mounted) return;
      setState(() => _reclamando = null);
      mostrarSnackbar(
        context,
        e.motivo == MotivoGamificacion.sorpresaYaAbierta
            ? 'Ya abriste la sorpresa de hoy'
            : 'Hoy no hay sorpresa',
      );
      _recargar();
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _reclamando = null);
      mostrarSnackbar(context, 'No pudimos reclamarlo. Intenta de nuevo.');
      return;
    }
    if (!mounted) return;
    // Antes de recargar: el botón de origen desaparece al reclamar.
    if (puntos > 0) {
      PuntosQueVuelan.lanzar(
        context,
        desde: origen,
        hasta: _llaveSaldo,
        texto: '+$puntos',
        alLlegar: () {
          Haptica.media();
          usuario?.cargar();
        },
      );
    }
    setState(() {
      _reclamando = null;
      _futuro = _leer();
    });
  }

  Future<void> _abrirSorpresa(GlobalKey origen) async {
    await _cobrar('sorpresa', origen, () async {
      final p = await widget.gamificacion.abrirSorpresa();
      if (mounted) setState(() => _sorpresaGanada = p);
      return p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final saldo = context
        .dependOnInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier
        ?.usuario
        ?.puntosTotales;
    return Scaffold(
      backgroundColor: colores.fondo,
      appBar: AppBar(
        title: const Text('Para reclamar'),
        actions: [
          if (saldo != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: KeyedSubtree(
                  key: _llaveSaldo,
                  child: ContadorPuntos(puntos: saldo),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<ParaReclamar>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const EsqueletoLista();
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar lo que tienes por reclamar.'),
                    const SizedBox(height: 12),
                    BotonApp(
                      texto: 'Reintentar',
                      variante: VarianteBoton.secundario,
                      onPressed: _recargar,
                    ),
                  ],
                ),
              ),
            );
          }
          final datos = snap.data!;
          final hayRetos = datos.logros.isNotEmpty || datos.misiones.isNotEmpty;
          final sorpresa = datos.sorpresa;
          final yaReclamadas = [
            for (final l in datos.retos.logros)
              for (var i = 0; i < l.nivel; i++) (l, i),
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (hayRetos) const _Titulo('Por reclamar'),
              for (final l in datos.logros)
                _TarjetaReclamo(
                  clave: 'logro-${l.id}',
                  icono: l.icono,
                  color: l.color,
                  titulo: 'Insignia ${l.nombre} ${_romanos[l.nivel]}',
                  detalle: l.descripcion,
                  puntos: l.puntosSiguiente,
                  reclamando: _reclamando == 'logro-${l.id}',
                  onReclamar: (origen) => _cobrar(
                    'logro-${l.id}',
                    origen,
                    () => widget.retos.reclamarLogro(l.id),
                  ),
                ),
              for (final m in datos.misiones)
                _TarjetaReclamo(
                  clave: 'mision-${m.id}',
                  icono: m.icono,
                  color: m.color,
                  titulo: m.titulo,
                  detalle: m.detalle,
                  puntos: m.puntos,
                  reclamando: _reclamando == 'mision-${m.id}',
                  onReclamar: (origen) => _cobrar(
                    'mision-${m.id}',
                    origen,
                    () => widget.retos.reclamarMision(m.id),
                  ),
                ),
              if (!hayRetos && !sorpresa.porAbrir && _sorpresaGanada == null)
                const _Vacio(),
              if (sorpresa.disponible) ...[
                const _Titulo('Sorpresa de hoy'),
                _TarjetaSorpresa(
                  sorpresa: sorpresa,
                  ganados: _sorpresaGanada,
                  abriendo: _reclamando == 'sorpresa',
                  onAbrir: _abrirSorpresa,
                ),
              ],
              if (yaReclamadas.isNotEmpty) ...[
                const _Titulo('Ya reclamadas'),
                for (final (l, i) in yaReclamadas)
                  _FilaReclamada(
                    clave: 'reclamada-${l.id}-$i',
                    texto: '${l.nombre} ${_romanos[i]}',
                    puntos: l.escalones[i].puntos,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(
      'No tienes nada por reclamar ahora. Sigue reciclando: cuando llegues a '
      'una meta, aparecerá aquí.',
      key: const Key('para-reclamar-vacio'),
      textAlign: TextAlign.center,
      style: TextStyle(color: context.colores.textoSecundario),
    ),
  );
}

class _Insignia extends StatelessWidget {
  final IconData icono;
  final Color color;

  const _Insignia({required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    final oscuro =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        icono,
        color: oscuro ? Colors.white : const Color(0xFF1E2B22),
      ),
    );
  }
}

BoxDecoration _caja(BuildContext context) {
  final colores = context.colores;
  return BoxDecoration(
    color: colores.superficie,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: colores.borde),
  );
}

/// Un logro o una misión lista, con su botón dorado de reclamar.
class _TarjetaReclamo extends StatefulWidget {
  final String clave;
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final int puntos;
  final bool reclamando;
  final void Function(GlobalKey origen) onReclamar;

  const _TarjetaReclamo({
    required this.clave,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.puntos,
    required this.reclamando,
    required this.onReclamar,
  });

  @override
  State<_TarjetaReclamo> createState() => _TarjetaReclamoState();
}

class _TarjetaReclamoState extends State<_TarjetaReclamo> {
  final _llaveBoton = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      key: Key('reclamo-${widget.clave}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _caja(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Insignia(icono: widget.icono, color: widget.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.detalle,
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: KeyedSubtree(
              key: _llaveBoton,
              child: BrilloRecompensa(
                child: BotonApp(
                  key: Key('reclamar-${widget.clave}'),
                  texto: 'Reclamar +${widget.puntos} Rebin Points',
                  variante: VarianteBoton.recompensa,
                  estado: widget.reclamando
                      ? EstadoBoton.cargando
                      : EstadoBoton.reposo,
                  onPressed: widget.reclamando
                      ? null
                      : () => widget.onReclamar(_llaveBoton),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaSorpresa extends StatefulWidget {
  final SorpresaHoy sorpresa;

  /// Puntos de la sorpresa que se acaba de abrir en esta pantalla.
  final int? ganados;
  final bool abriendo;
  final void Function(GlobalKey origen) onAbrir;

  const _TarjetaSorpresa({
    required this.sorpresa,
    required this.ganados,
    required this.abriendo,
    required this.onAbrir,
  });

  @override
  State<_TarjetaSorpresa> createState() => _TarjetaSorpresaState();
}

class _TarjetaSorpresaState extends State<_TarjetaSorpresa> {
  final _llaveBoton = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final s = widget.sorpresa;
    final ganados = widget.ganados;
    return Container(
      key: const Key('sorpresa-hoy'),
      padding: const EdgeInsets.all(14),
      decoration: _caja(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: Movimiento.dur(context, Movimiento.transicion),
                switchInCurve: Movimiento.rebote,
                transitionBuilder: (hijo, anim) =>
                    ScaleTransition(scale: anim, child: hijo),
                child: s.abierta
                    ? Icon(
                        Icons.celebration,
                        key: const ValueKey('abierta'),
                        size: 40,
                        color: colores.recompensaTexto,
                      )
                    : Icon(
                        Icons.card_giftcard,
                        key: const ValueKey('cerrada'),
                        size: 40,
                        color: colores.recompensaTexto,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ganados != null
                          ? '+$ganados Rebin Points'
                          : s.abierta
                          ? 'Ya la abriste hoy'
                          : 'Una sorpresa para ti',
                      key: const Key('sorpresa-titulo'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ganados != null ? colores.recompensaTexto : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aparece algunos días, sin aviso.',
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (s.porAbrir) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: KeyedSubtree(
                key: _llaveBoton,
                child: BotonApp(
                  key: const Key('abrir-sorpresa'),
                  texto: 'Abrir',
                  variante: VarianteBoton.recompensa,
                  estado: widget.abriendo
                      ? EstadoBoton.cargando
                      : EstadoBoton.reposo,
                  onPressed: widget.abriendo
                      ? null
                      : () => widget.onAbrir(_llaveBoton),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaReclamada extends StatelessWidget {
  final String clave;
  final String texto;
  final int puntos;

  const _FilaReclamada({
    required this.clave,
    required this.texto,
    required this.puntos,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Padding(
      key: Key(clave),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colores.primario, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
          Pill(
            texto: '+$puntos',
            color: colores.recompensaTexto,
            fondo: colores.recompensaSuave,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
        ],
      ),
    );
  }
}
