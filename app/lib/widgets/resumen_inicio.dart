import 'package:flutter/material.dart';

import '../models/nivel.dart';
import '../models/resumen_hoy.dart';
import '../repositories/gamificacion_por_defecto.dart';
import '../repositories/gamificacion_repository.dart';
import '../repositories/para_reclamar.dart';
import '../repositories/retos_por_defecto.dart';
import '../repositories/retos_repository.dart';
import '../state/usuario_controller.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import 'anillo_meta.dart';
import '../screens/para_reclamar_screen.dart';
import '../screens/racha_screen.dart';
import 'pill.dart';
import 'presionable.dart';

/// Cabecera de Inicio, dentro de la lista deslizable del mapa: saludo con la
/// comuna, los Rebin Points del saldo, la meta y la racha de hoy, y el nivel
/// con su avance hacia el siguiente (por puntos acumulados, con los umbrales
/// de la nube).
class ResumenInicio extends StatefulWidget {
  /// Solo para tests: inyecta un repositorio (ej. mock) en vez del que elige
  /// [gamificacionPorDefecto].
  final GamificacionRepository? gamificacion;

  /// Solo para tests: los retos que cuentan para "para reclamar".
  final RetosRepository? retos;

  /// Cada aviso de este [Listenable] vuelve a leer la meta y la racha (al
  /// volver a la pestaña Inicio o del flujo Reciclar).
  final Listenable? recarga;

  /// Hora actual (reemplazable en tests).
  final DateTime Function()? ahora;

  const ResumenInicio({
    super.key,
    this.gamificacion,
    this.retos,
    this.recarga,
    this.ahora,
  });

  @override
  State<ResumenInicio> createState() => _ResumenInicioState();
}

class _ResumenInicioState extends State<ResumenInicio> {
  late final GamificacionRepository _repositorio =
      widget.gamificacion ?? gamificacionPorDefecto();

  late final RetosRepository _retos = widget.retos ?? retosPorDefecto();

  /// null mientras carga o si falló: Inicio sigue mostrando el nivel.
  ResumenHoy? _hoy;

  /// Cuántas cosas hay para reclamar; 0 también si no se pudo leer.
  int _paraReclamar = 0;

  @override
  void initState() {
    super.initState();
    widget.recarga?.addListener(_cargar);
    _cargar();
  }

  @override
  void didUpdateWidget(ResumenInicio anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.recarga != widget.recarga) {
      anterior.recarga?.removeListener(_cargar);
      widget.recarga?.addListener(_cargar);
    }
  }

  @override
  void dispose() {
    widget.recarga?.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    _contarParaReclamar();
    try {
      final hoy = await _repositorio.resumenHoy();
      if (mounted) setState(() => _hoy = hoy);
    } catch (e) {
      debugPrint('ResumenInicio: no se pudo leer la meta de hoy ($e)');
      if (mounted && _hoy == null) setState(() {});
    }
  }

  Future<void> _contarParaReclamar() async {
    try {
      final r = await ParaReclamar.cargar(_retos, _repositorio);
      if (mounted) setState(() => _paraReclamar = r.total);
    } catch (e) {
      debugPrint('ResumenInicio: no se pudo contar lo por reclamar ($e)');
    }
  }

  Future<void> _abrirParaReclamar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ParaReclamarScreen(retos: _retos, gamificacion: _repositorio),
      ),
    );
    if (mounted) _cargar();
  }

  /// Abre Tu racha y, al volver, relee la meta y los congeladores.
  Future<void> _abrirRacha() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RachaScreen(repositorio: _repositorio),
      ),
    );
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final usuario = UsuarioScope.of(context).usuario;
    final hoy = _hoy;
    final tabla = usuario?.niveles ?? Nivel.porDefecto;
    final nivel = usuario == null
        ? null
        : Nivel.paraPuntos(usuario.puntosAcumulados, tabla);
    final siguiente = nivel?.siguienteEn(tabla);

    return Padding(
      key: const Key('inicio-resumen'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          if (_paraReclamar > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Presionable(
                onTap: _abrirParaReclamar,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    child: Pill(
                      key: const Key('inicio-para-reclamar'),
                      icono: Icons.card_giftcard,
                      texto: '$_paraReclamar para reclamar',
                      color: colores.recompensaTexto,
                      fondo: colores.recompensaSuave,
                      fontWeight: FontWeight.w700,
                      gap: 6,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (hoy != null) ...[
            const SizedBox(height: 12),
            _Hoy(
              resumen: hoy,
              ahora: (widget.ahora ?? DateTime.now)(),
              onRacha: _abrirRacha,
            ),
          ],
          if (usuario != null) ...[
            const SizedBox(height: 10),
            _NivelBarra(
              puntos: usuario.puntosAcumulados,
              niveles: usuario.niveles,
            ),
            if (hoy != null)
              _Consejo(
                metaCumplida: hoy.metaCumplida,
                faltan: siguiente == null
                    ? null
                    : siguiente.puntosMinimos - usuario.puntosAcumulados,
                siguiente: siguiente,
              ),
          ],
        ],
      ),
    );
  }
}

const _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
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

/// "jueves 15 de octubre". `intl` no está en el proyecto.
String _fechaLarga(DateTime f) =>
    '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]}';

/// Título "Hoy" con la fecha y las tarjetas de meta y racha.
class _Hoy extends StatelessWidget {
  final ResumenHoy resumen;
  final DateTime ahora;
  final VoidCallback onRacha;

  const _Hoy({
    required this.resumen,
    required this.ahora,
    required this.onRacha,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      key: const Key('inicio-hoy'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Hoy', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fechaLarga(ahora),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colores.textoSecundario, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _TarjetaMeta(resumen: resumen)),
              const SizedBox(width: 10),
              Expanded(
                child: Presionable(
                  onTap: onRacha,
                  child: _TarjetaRacha(dias: resumen.racha),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Widget hijo;

  const _Tarjeta({required this.hijo});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colores.borde),
      ),
      child: hijo,
    );
  }
}

class _TarjetaMeta extends StatelessWidget {
  final ResumenHoy resumen;

  const _TarjetaMeta({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final objetivo = resumen.metaObjetivo;
    return _Tarjeta(
      hijo: Row(
        key: const Key('hoy-meta'),
        children: [
          AnilloMeta(
            progreso: resumen.metaCumplida || objetivo == 0
                ? 1
                : resumen.metaActual / objetivo,
            etiqueta: '${resumen.metaActual}/$objetivo',
            tamano: 48,
            dorado: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objetivo == 1 ? 'Recicla 1 cosa' : 'Recicla $objetivo cosas',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resumen.metaCumplida ? '¡Lista por hoy!' : 'Tu meta de hoy',
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
  }
}

class _TarjetaRacha extends StatelessWidget {
  final int dias;

  const _TarjetaRacha({required this.dias});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return _Tarjeta(
      hijo: Row(
        key: const Key('hoy-racha'),
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colores.primarioSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: colores.primarioTexto, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dias == 0
                      ? 'Empieza tu racha'
                      : 'Racha de $dias ${dias == 1 ? "día" : "días"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu planta crece contigo',
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
  }
}

/// Una línea bajo la barra de nivel: qué falta hoy.
class _Consejo extends StatelessWidget {
  final bool metaCumplida;

  /// Rebin Points que faltan para [siguiente]; null en el último nivel.
  final int? faltan;
  final Nivel? siguiente;

  const _Consejo({
    required this.metaCumplida,
    required this.faltan,
    required this.siguiente,
  });

  @override
  Widget build(BuildContext context) {
    final texto = metaCumplida
        ? 'Volviste a reciclar hoy. Mañana sigue tu racha.'
        : 'Escanea algo para completar la meta.'
              '${faltan != null && faltan! <= 20 ? " Estás a $faltan Rebin Points de ${siguiente!.nombre}." : ""}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          texto,
          key: const Key('inicio-consejo'),
          style: TextStyle(
            color: context.colores.textoSecundario,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Nivel y avance hacia el siguiente, con los Rebin Points acumulados.
class _NivelBarra extends StatelessWidget {
  final int puntos;

  /// Umbrales de la tabla `niveles`; null si no se pudieron leer (se usa la
  /// copia de la app).
  final List<Nivel>? niveles;

  const _NivelBarra({required this.puntos, this.niveles});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final tabla = niveles ?? Nivel.porDefecto;
    final nivel = Nivel.paraPuntos(puntos, tabla);
    final siguiente = nivel.siguienteEn(tabla);
    final progreso = siguiente == null
        ? 1.0
        : ((puntos - nivel.puntosMinimos) /
                  (siguiente.puntosMinimos - nivel.puntosMinimos))
              .clamp(0.0, 1.0)
              .toDouble();
    return Column(
      key: const Key('inicio-nivel'),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                siguiente == null
                    ? '${nivel.nombre} · $puntos Rebin Points'
                    : '${nivel.nombre} · $puntos / ${siguiente.puntosMinimos}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (siguiente != null)
              Text(
                'Te faltan ${siguiente.puntosMinimos - puntos} para ${siguiente.nombre}',
                style: TextStyle(
                  color: colores.textoSecundario,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            backgroundColor: colores.primarioSuave,
            valueColor: AlwaysStoppedAnimation(colores.primario),
          ),
        ),
      ],
    );
  }
}
