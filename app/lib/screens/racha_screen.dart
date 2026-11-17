import 'package:flutter/material.dart';

import '../models/resumen_hoy.dart';
import '../repositories/gamificacion_repository.dart';
import '../services/recordatorio_racha_store.dart';
import '../state/usuario_controller.dart';
import '../theme/app_radius.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/boton_app.dart';
import '../widgets/planta_racha.dart';
import '../widgets/toast_rebin.dart';

/// Tu racha: la planta con una hoja por día, la semana, los congeladores y el
/// recordatorio. La racha y los congeladores los calcula la base; la app solo
/// los muestra y canjea un congelador con `app_comprar_congelador`.
class RachaScreen extends StatefulWidget {
  final GamificacionRepository repositorio;

  const RachaScreen({super.key, required this.repositorio});

  @override
  State<RachaScreen> createState() => _RachaScreenState();
}

class _RachaScreenState extends State<RachaScreen> {
  late Future<ResumenHoy> _futuro = widget.repositorio.resumenHoy();
  bool _comprando = false;
  bool _recordatorio = true;

  @override
  void initState() {
    super.initState();
    RecordatorioRachaStore.leer().then((v) {
      if (mounted) setState(() => _recordatorio = v);
    });
  }

  void _reintentar() {
    setState(() {
      _futuro = widget.repositorio.resumenHoy();
    });
  }

  Future<void> _canjear(ResumenHoy r) async {
    final usuario = UsuarioScope.of(context);
    final confirmado = await mostrarAppBottomSheet<bool>(
      context: context,
      builder: (_) => _ConfirmarCanje(
        costo: r.costoCongelador,
        saldo: usuario.usuario?.puntosTotales,
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _comprando = true);
    try {
      await widget.repositorio.comprarCongelador();
    } on GamificacionException catch (e) {
      if (!mounted) return;
      setState(() => _comprando = false);
      mostrarSnackbar(context, switch (e.motivo) {
        MotivoGamificacion.puntosInsuficientes =>
          'Te faltan Rebin Points para canjearlo',
        MotivoGamificacion.congeladoresAlMaximo =>
          'Ya tienes el máximo de congeladores',
        // Las de la sorpresa no salen de canjear un congelador.
        MotivoGamificacion.sinSorpresaHoy ||
        MotivoGamificacion.sorpresaYaAbierta =>
          'No pudimos canjearlo. Intenta de nuevo.',
      });
      // Si ya estaba al máximo, el botón debe reflejarlo.
      _reintentar();
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _comprando = false);
      mostrarSnackbar(context, 'No pudimos canjearlo. Intenta de nuevo.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _comprando = false;
      _futuro = widget.repositorio.resumenHoy();
    });
    ToastRebin.mostrar(context, 'Guardaste un congelador');
    usuario.cargar();
  }

  Future<void> _cambiarRecordatorio(bool valor) async {
    setState(() => _recordatorio = valor);
    await RecordatorioRachaStore.guardar(valor);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      backgroundColor: colores.fondo,
      appBar: AppBar(title: const Text('Tu racha')),
      body: FutureBuilder<ResumenHoy>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No pudimos cargar tu racha.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    BotonApp(
                      texto: 'Reintentar',
                      onPressed: _reintentar,
                      variante: VarianteBoton.secundario,
                    ),
                  ],
                ),
              ),
            );
          }
          final r = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _TarjetaPlanta(resumen: r),
              const SizedBox(height: 16),
              _Semana(dias: r.semana),
              const SizedBox(height: 16),
              // La base aún no tiene congeladores (máximo 0): no se muestran.
              if (r.maxCongeladores > 0) ...[
                _Congelar(
                  resumen: r,
                  comprando: _comprando,
                  onCanjear: () => _canjear(r),
                ),
                const SizedBox(height: 16),
              ],
              _AvisoPrevio(
                racha: r.racha,
                activo: _recordatorio,
                onCambio: _cambiarRecordatorio,
              ),
              const SizedBox(height: 16),
              const _SiSeCorta(),
            ],
          );
        },
      ),
    );
  }
}

class _Caja extends StatelessWidget {
  final Widget hijo;
  final Color? fondo;

  const _Caja({required this.hijo, this.fondo});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    // Material y no un DecoratedBox: el interruptor de la tarjeta pinta su
    // fondo y su salpicadura en el Material más cercano.
    return Material(
      color: fondo ?? colores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(width: double.infinity, child: hijo),
      ),
    );
  }
}

class _TarjetaPlanta extends StatelessWidget {
  final ResumenHoy resumen;

  const _TarjetaPlanta({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final d = resumen.racha;
    return _Caja(
      hijo: Column(
        children: [
          PlantaRacha(dias: d),
          const SizedBox(height: 8),
          Text(
            '$d ${d == 1 ? "día" : "días"}',
            key: const Key('racha-dias'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Una hoja por cada día que reciclas',
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.textoSecundario),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu mejor racha: ${resumen.rachaMaxima} días',
            style: TextStyle(
              color: colores.primarioTexto,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

const _letras = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _nombres = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

class _Semana extends StatelessWidget {
  final List<DiaRacha> dias;

  const _Semana({required this.dias});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('racha-semana'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < dias.length && i < 7; i++)
          _CirculoDia(indice: i, dia: dias[i]),
      ],
    );
  }
}

class _CirculoDia extends StatelessWidget {
  final int indice;
  final DiaRacha dia;

  const _CirculoDia({required this.indice, required this.dia});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final estado = dia.estado;
    final (fondo, borde, icono, colorIcono) = switch (estado) {
      EstadoDia.hecho => (
        colores.primario,
        colores.primario,
        Icons.eco,
        colores.sobrePrimario,
      ),
      EstadoDia.congelado => (
        colores.infoSuave,
        colores.info,
        Icons.ac_unit,
        colores.infoTexto,
      ),
      EstadoDia.hoy => (
        colores.fondo,
        colores.primario,
        null,
        colores.primario,
      ),
      EstadoDia.pendiente => (
        colores.superficieAlta,
        colores.borde,
        null,
        colores.textoSecundario,
      ),
      EstadoDia.futuro => (
        Colors.transparent,
        colores.borde,
        null,
        colores.textoSecundario,
      ),
    };
    final texto = switch (estado) {
      EstadoDia.hecho => 'hecho',
      EstadoDia.congelado => 'congelado',
      EstadoDia.hoy => 'hoy',
      EstadoDia.pendiente => 'sin reciclar',
      EstadoDia.futuro => 'todavía no',
    };
    return Semantics(
      container: true,
      label: '${_nombres[indice]}: $texto',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(
              _letras[indice],
              style: TextStyle(
                color: colores.textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              key: Key('racha-dia-$indice-${estado.name}'),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: fondo,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borde,
                  width: estado == EstadoDia.hoy ? 2.5 : 1.5,
                ),
              ),
              child: icono == null
                  ? null
                  : Icon(icono, size: 20, color: colorIcono),
            ),
          ],
        ),
      ),
    );
  }
}

class _Congelar extends StatelessWidget {
  final ResumenHoy resumen;
  final bool comprando;
  final VoidCallback onCanjear;

  const _Congelar({
    required this.resumen,
    required this.comprando,
    required this.onCanjear,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final n = resumen.congeladores;
    final alMaximo = n >= resumen.maxCongeladores;
    final saldo = UsuarioScope.of(context).usuario?.puntosTotales;
    final faltan = saldo == null ? 0 : resumen.costoCongelador - saldo;
    return _Caja(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.ac_unit, color: colores.info),
              const SizedBox(width: 8),
              Text(
                'Congelar racha',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '¿Un día sin tiempo? Tu racha te espera.',
            style: TextStyle(color: colores.textoSecundario),
          ),
          const SizedBox(height: 4),
          Text(
            n == 0
                ? 'No tienes ninguno guardado.'
                : 'Tienes $n ${n == 1 ? "guardado" : "guardados"}.',
            key: const Key('racha-congeladores'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BotonApp(
              texto: alMaximo
                  ? 'Ya tienes el máximo (${resumen.maxCongeladores})'
                  : faltan > 0
                  ? 'Te faltan $faltan Rebin Points para uno'
                  : 'Canjear ${n == 0 ? "uno" : "otro"} por '
                        '${resumen.costoCongelador} Rebin Points',
              onPressed: alMaximo || faltan > 0 || comprando ? null : onCanjear,
              variante: VarianteBoton.secundario,
              estado: comprando ? EstadoBoton.cargando : EstadoBoton.reposo,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmarCanje extends StatelessWidget {
  final int costo;
  final int? saldo;

  const _ConfirmarCanje({required this.costo, required this.saldo});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guardar un congelador',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            saldo == null
                ? 'Usa $costo de tus Rebin Points.'
                : 'Usa $costo de tus $saldo Rebin Points.',
            key: const Key('racha-confirmar-texto'),
            style: TextStyle(color: colores.textoSecundario),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: BotonApp(
              texto: 'Canjear',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: BotonApp(
              texto: 'Ahora no',
              variante: VarianteBoton.terciario,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista previa del aviso de las 19:00 y el interruptor para silenciarlo.
/// Las notificaciones reales no existen todavía (falta aprobar FCM): el
/// interruptor solo guarda la preferencia.
class _AvisoPrevio extends StatelessWidget {
  final int racha;
  final bool activo;
  final ValueChanged<bool> onCambio;

  const _AvisoPrevio({
    required this.racha,
    required this.activo,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return _Caja(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así se ve el aviso (19:00, solo si hace falta)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('racha-aviso'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colores.superficieAlta,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco, color: colores.primarioTexto),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rebin',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        racha == 0
                            ? 'Hoy puede brotar tu planta: recicla algo y '
                                  'empieza tu racha.'
                            : 'Tu planta va en $racha '
                                  '${racha == 1 ? "día" : "días"}. Si hoy '
                                  'reciclas algo, suma una hoja más.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const Key('racha-recordatorio'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Recordatorio amable'),
            subtitle: Text(
              'Pronto: aún no enviamos avisos',
              style: TextStyle(color: colores.textoSecundario),
            ),
            value: activo,
            onChanged: onCambio,
          ),
        ],
      ),
    );
  }
}

class _SiSeCorta extends StatelessWidget {
  const _SiSeCorta();

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return _Caja(
      fondo: colores.primarioSuave,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Si un día se corta',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'La planta no se seca. Queda guardada en tu perfil como tu mejor '
            'racha y aparece un brote nuevo. Te diremos: "Empezamos de nuevo. '
            'Tu planta de 7 días sigue aquí."',
          ),
        ],
      ),
    );
  }
}
