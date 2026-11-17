import 'package:flutter/material.dart';

import '../models/comunidad_hoy.dart';
import '../models/reto.dart';
import '../repositories/comunidad_repository.dart';
import '../repositories/retos_repository.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tipografia.dart';
import '../widgets/esqueleto.dart';
import '../widgets/estado_pantalla.dart';
import 'retos_screen.dart';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "1.710" con punto de miles.
String _miles(int n) {
  final t = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < t.length; i++) {
    if (i > 0 && (t.length - i) % 3 == 0) b.write('.');
    b.write(t[i]);
  }
  return b.toString();
}

Widget _cargando() => const EsqueletoLista(filas: 3, conTitulo: false);

Widget _error(VoidCallback reintentar) => Center(
  child: SingleChildScrollView(
    child: EstadoPantalla(
      icono: Icons.wifi_off_outlined,
      titulo: 'No pudimos cargar esto',
      texto: 'Revisa tu conexión e intenta de nuevo.',
      accion: 'Reintentar',
      onAccion: reintentar,
    ),
  ),
);

/// Pestaña Hoy: la meta del mes de la comuna, la misión de la semana más
/// cercana a completarse y el acceso a confirmar puntos cercanos.
class HoyComunidad extends StatefulWidget {
  final ComunidadRepository repositorio;
  final RetosRepository retos;
  final String comuna;

  const HoyComunidad({
    super.key,
    required this.repositorio,
    required this.retos,
    required this.comuna,
  });

  @override
  State<HoyComunidad> createState() => _HoyComunidadState();
}

class _HoyComunidadState extends State<HoyComunidad> {
  late Future<MetaComuna> _meta = widget.repositorio.metaComuna(widget.comuna);
  late Future<Retos?> _retos = _leerRetos();

  /// La misión no es esencial: si falla se intenta una vez más tras una
  /// pausa (el primer error suele ser el token recién emitido, PGRST303) y,
  /// si vuelve a fallar, Hoy se muestra sin ella.
  Future<Retos?> _leerRetos() async {
    for (var intento = 1; intento <= 2; intento++) {
      try {
        return await widget.retos.retos();
      } catch (e) {
        debugPrint('Comunidad: no se pudo leer la misión ($e)');
        if (intento == 2) break;
        await Future<void>.delayed(UsuarioController.pausaReintento);
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(HoyComunidad anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.comuna != widget.comuna) _recargar();
  }

  Future<void> _recargar() async {
    setState(() {
      _meta = widget.repositorio.metaComuna(widget.comuna);
      _retos = _leerRetos();
    });
    await Future.wait([_meta.catchError((_) => _vacia), _retos]);
  }

  MetaComuna get _vacia => MetaComuna(
    comuna: widget.comuna,
    objetivo: null,
    actual: 0,
    vecinos: 0,
    tuAporte: 0,
    diasRestantes: 0,
  );

  Future<void> _abrirRetos() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RetosScreen(repositorio: widget.retos),
      ),
    );
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MetaComuna>(
      future: _meta,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return _cargando();
        }
        if (snap.hasError || !snap.hasData) return _error(_recargar);
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _TarjetaMeta(meta: snap.data!),
              FutureBuilder<Retos?>(
                future: _retos,
                builder: (context, r) {
                  final mision = _misionCercana(r.data);
                  if (mision == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _TarjetaMision(mision: mision, onTap: _abrirRetos),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// La misión sin reclamar más avanzada (la que conviene recordar).
  static Mision? _misionCercana(Retos? retos) {
    final pendientes = [
      for (final m in retos?.misiones ?? const <Mision>[])
        if (!m.reclamada) m,
    ]..sort((a, b) => b.progreso.compareTo(a.progreso));
    return pendientes.isEmpty ? null : pendientes.first;
  }
}

class _TarjetaMeta extends StatelessWidget {
  final MetaComuna meta;

  const _TarjetaMeta({required this.meta});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final m = meta;
    final mes = m.mes == null ? '' : ' · ${_meses[m.mes!.month - 1]}';
    final texto = TextStyle(color: colores.sobrePrimario);
    final suave = TextStyle(
      color: colores.sobrePrimario.withValues(alpha: 0.8),
      fontSize: 13,
    );
    return Container(
      key: const Key('comunidad-meta'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colores.primario,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'META DE ${m.comuna.toUpperCase()}${mes.toUpperCase()}',
            style: suave.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          if (m.objetivo == null) ...[
            Text(
              'Aún no hay una meta este mes',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: colores.sobrePrimario),
            ),
            const SizedBox(height: 6),
            Text(
              'Este mes los vecinos reciclaron ${_miles(m.actual)} objetos.',
              style: suave,
            ),
          ] else ...[
            Text(
              'Juntos, ${_miles(m.objetivo!)} objetos reciclados este mes',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: colores.sobrePrimario),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: m.progreso,
                minHeight: 10,
                backgroundColor: colores.sobrePrimario.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(colores.sobrePrimario),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_miles(m.actual)} objetos',
                  style: texto.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: Tipografia.cifras,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${_miles(m.vecinos)} vecinos · quedan ${m.diasRestantes} días',
                    textAlign: TextAlign.end,
                    style: suave,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            m.tuAporte == 0
                ? 'Todavía no aportas este mes. Tu primer reciclaje ya suma.'
                : 'Tú aportaste ${_miles(m.tuAporte)} '
                      '${m.tuAporte == 1 ? 'objeto' : 'objetos'} este mes.',
            style: texto.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMision extends StatelessWidget {
  final Mision mision;
  final VoidCallback onTap;

  const _TarjetaMision({required this.mision, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final m = mision;
    return Material(
      color: colores.superficie,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('comunidad-mision'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: m.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icono, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.lista ? '¡Lista para reclamar!' : m.detalle,
                      style: TextStyle(
                        color: m.lista
                            ? colores.recompensaTexto
                            : colores.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        value: m.progreso,
                        minHeight: 6,
                        backgroundColor: colores.superficieAlta,
                        valueColor: AlwaysStoppedAnimation(colores.primario),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${m.actual} / ${m.meta}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: Tipografia.cifras,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pestaña Actividad: lo último en la comuna (reportes, puntos nuevos y
/// reciclajes agrupados, sin nombres en los depósitos).
class ActividadComunidad extends StatefulWidget {
  final ComunidadRepository repositorio;
  final String comuna;

  /// Hora actual (reemplazable en tests).
  final DateTime Function()? ahora;

  const ActividadComunidad({
    super.key,
    required this.repositorio,
    required this.comuna,
    this.ahora,
  });

  @override
  State<ActividadComunidad> createState() => _ActividadComunidadState();
}

class _ActividadComunidadState extends State<ActividadComunidad> {
  late Future<List<ActividadComuna>> _futuro = widget.repositorio.actividad(
    widget.comuna,
  );

  @override
  void didUpdateWidget(ActividadComunidad anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.comuna != widget.comuna) _recargar();
  }

  Future<void> _recargar() async {
    setState(() {
      _futuro = widget.repositorio.actividad(widget.comuna);
    });
    await _futuro.catchError((_) => <ActividadComuna>[]);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final ahora = (widget.ahora ?? DateTime.now)();
    return FutureBuilder<List<ActividadComuna>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return _cargando();
        }
        if (snap.hasError || !snap.hasData) return _error(_recargar);
        final lista = snap.data!;
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                'Lo último en tu barrio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (lista.isEmpty)
                EstadoPantalla(
                  icono: Icons.forum_outlined,
                  titulo: 'Todavía no hay actividad en ${widget.comuna}',
                  texto:
                      'Cuando tus vecinos reporten, reciclen o agreguen '
                      'puntos, aparecerá aquí.',
                )
              else
                for (final a in lista)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colores.primarioSuave,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            switch (a.tipo) {
                              TipoActividad.reporte => Icons.flag_outlined,
                              TipoActividad.puntoNuevo =>
                                Icons.add_location_alt_outlined,
                              TipoActividad.reciclaje => Icons.recycling,
                              TipoActividad.otro => Icons.eco_outlined,
                            },
                            size: 20,
                            color: colores.primarioTexto,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${a.alias} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: a.texto),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          haceCuanto(a.fecha, ahora),
                          style: TextStyle(
                            color: colores.textoSecundario,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Pestaña Ranking: los Rebin Points ganados esta semana (de lunes a hoy).
/// Es de todo Rebin, no de la comuna: la base no guarda la comuna de cada
/// persona. Solo muestra alias y se puede salir.
class RankingComunidad extends StatefulWidget {
  final ComunidadRepository repositorio;

  const RankingComunidad({super.key, required this.repositorio});

  @override
  State<RankingComunidad> createState() => _RankingComunidadState();
}

class _RankingComunidadState extends State<RankingComunidad> {
  late Future<List<PuestoRanking>> _futuro = widget.repositorio.ranking();
  bool _cambiando = false;

  Future<void> _recargar() async {
    setState(() {
      _futuro = widget.repositorio.ranking();
    });
    await _futuro.catchError((_) => <PuestoRanking>[]);
  }

  Future<void> _ocultar(bool oculto) async {
    if (oculto) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Salir del ranking?'),
          content: const Text(
            'Dejarás de aparecer en el ranking y en la actividad saldrás como '
            '"Un vecino". Tus Rebin Points no cambian y puedes volver cuando '
            'quieras.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _cambiando = true);
    try {
      await widget.repositorio.ocultarRanking(oculto);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cambiarlo. Intenta de nuevo.'),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _cambiando = false);
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return FutureBuilder<List<PuestoRanking>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return _cargando();
        }
        if (snap.hasError || !snap.hasData) return _error(_recargar);
        final lista = snap.data!;
        final estoy = lista.any((p) => p.esTuyo);
        return RefreshIndicator(
          onRefresh: _recargar,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                'Esta semana',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Se reinicia el lunes, así que todos parten de cero. Es el '
                'ranking de todo Rebin.',
                style: TextStyle(color: colores.textoSecundario, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (lista.isEmpty)
                const EstadoPantalla(
                  icono: Icons.emoji_events_outlined,
                  titulo: 'Nadie suma todavía esta semana',
                  texto: 'Recicla o reporta un punto y serás el primero.',
                )
              else
                for (final p in lista) _FilaRanking(puesto: p),
              const SizedBox(height: 12),
              Text(
                'Solo se ven alias y Rebin Points de la semana.',
                style: TextStyle(color: colores.textoSecundario, fontSize: 12),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('ranking-salir'),
                  onPressed: _cambiando ? null : () => _ocultar(estoy),
                  child: Text(
                    estoy
                        ? 'Salir del ranking'
                        : 'Volver a aparecer en el ranking',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilaRanking extends StatelessWidget {
  final PuestoRanking puesto;

  const _FilaRanking({required this.puesto});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final p = puesto;
    return Semantics(
      label:
          'Puesto ${p.posicion}: ${p.esTuyo ? 'tú' : p.alias}, '
          '${p.puntos} Rebin Points',
      excludeSemantics: true,
      child: Container(
        key: Key('ranking-${p.posicion}'),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.esTuyo ? colores.primarioSuave : colores.superficie,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${p.posicion}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: p.esTuyo
                      ? colores.primarioTexto
                      : colores.textoSecundario,
                ),
              ),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: colores.superficieAlta,
              child: Text(
                p.alias.isEmpty ? '?' : p.alias.characters.first.toUpperCase(),
                style: TextStyle(
                  color: colores.texto,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p.esTuyo ? '${p.alias} (tú)' : p.alias,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.star, size: 16, color: colores.recompensa),
            const SizedBox(width: 4),
            Text(
              '${p.puntos}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFeatures: Tipografia.cifras,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
