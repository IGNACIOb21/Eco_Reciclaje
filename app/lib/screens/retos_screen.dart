import 'package:flutter/material.dart';

import '../models/reto.dart';
import '../repositories/retos_repository.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import '../widgets/boton_app.dart';
import '../widgets/pill.dart';
import '../widgets/esqueleto.dart';
import '../widgets/estado_pantalla.dart';

/// Misiones de la semana y logros con niveles. El avance lo calcula la base;
/// reclamar acredita los Rebin Points y actualiza el saldo del usuario.
class RetosScreen extends StatefulWidget {
  final RetosRepository repositorio;

  /// 0 = Misiones, 1 = Logros.
  final int pestanaInicial;

  const RetosScreen({
    super.key,
    required this.repositorio,
    this.pestanaInicial = 0,
  });

  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  late Future<Retos> _futuro = widget.repositorio.retos();
  String? _reclamando;
  int _ganados = 0;

  Future<void> _reclamar(Mision m) =>
      _cobrar('mision-${m.id}', () => widget.repositorio.reclamarMision(m.id));

  Future<void> _reclamarLogro(Logro l) =>
      _cobrar('logro-${l.id}', () => widget.repositorio.reclamarLogro(l.id));

  /// Reclama, suma lo ganado y vuelve a leer los retos y el saldo.
  Future<void> _cobrar(String clave, Future<int> Function() reclamar) async {
    final usuario = context
        .getInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    setState(() => _reclamando = clave);
    int puntos;
    try {
      puntos = await reclamar();
    } catch (_) {
      if (!mounted) return;
      setState(() => _reclamando = null);
      mostrarSnackbar(context, 'No pudimos reclamarlo. Intenta de nuevo.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _reclamando = null;
      _ganados += puntos;
      _futuro = widget.repositorio.retos();
    });
    if (puntos > 0) usuario?.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.pestanaInicial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Retos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Misiones'),
              Tab(text: 'Logros'),
            ],
          ),
        ),
        body: FutureBuilder<Retos>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return const EsqueletoLista();
            }
            if (snap.hasError || !snap.hasData) {
              return Center(
                child: EstadoPantalla(
                  icono: Icons.wifi_off_outlined,
                  titulo: 'No pudimos cargar tus retos',
                  texto: 'Revisa tu conexión e intenta de nuevo.',
                  accion: 'Reintentar',
                  onAccion: () =>
                      setState(() => _futuro = widget.repositorio.retos()),
                ),
              );
            }
            final retos = snap.data!;
            final hechas = retos.misiones.where((m) => m.reclamada).length;
            return TabBarView(
              children: [
                // La base aún no tiene misiones: un aviso en vez de "0 de 0".
                if (retos.misiones.isEmpty)
                  const Center(
                    child: EstadoPantalla(
                      key: Key('misiones-vacio'),
                      icono: Icons.flag_outlined,
                      titulo: 'Pronto habrá misiones',
                      texto:
                          'Mientras tanto, sigue reciclando para avanzar en '
                          'tus logros.',
                    ),
                  )
                else
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ResumenSemana(
                        hechas: hechas,
                        total: retos.misiones.length,
                      ),
                      if (_ganados > 0) ...[
                        const SizedBox(height: 8),
                        Pill(
                          icono: Icons.star,
                          texto: '+$_ganados Rebin Points',
                          color: colores.recompensaTexto,
                          fondo: colores.recompensaSuave,
                        ),
                      ],
                      const SizedBox(height: 12),
                      for (final m in retos.misiones)
                        _MisionCard(
                          mision: m,
                          reclamando: _reclamando == 'mision-${m.id}',
                          onReclamar: () => _reclamar(m),
                        ),
                    ],
                  ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final l in retos.logros)
                      _LogroCard(
                        logro: l,
                        reclamando: _reclamando == 'logro-${l.id}',
                        onReclamar: () => _reclamarLogro(l),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Esta semana", cuándo se renuevan las misiones (cada lunes, como en la
/// base) y cuántas van reclamadas, sin presión.
class _ResumenSemana extends StatelessWidget {
  final int hechas;
  final int total;

  const _ResumenSemana({required this.hechas, required this.total});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final dias = 8 - DateTime.now().weekday;
    return Column(
      key: const Key('retos-resumen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Esta semana',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            Text(
              dias == 1 ? 'Se renueva mañana' : 'Se renueva en $dias días',
              style: TextStyle(color: colores.textoSecundario, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : hechas / total,
            minHeight: 6,
            backgroundColor: colores.superficieAlta,
            valueColor: AlwaysStoppedAnimation(colores.primario),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$hechas de $total completadas. Sin presión: lo que no hagas '
          'simplemente se renueva.',
          style: TextStyle(color: colores.textoSecundario, fontSize: 12),
        ),
      ],
    );
  }
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        icono,
        color: oscuro ? Colors.white : const Color(0xFF1E2B22),
      ),
    );
  }
}

class _MisionCard extends StatelessWidget {
  final Mision mision;
  final bool reclamando;
  final VoidCallback onReclamar;

  const _MisionCard({
    required this.mision,
    required this.reclamando,
    required this.onReclamar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final m = mision;
    return Container(
      key: Key('mision-${m.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Insignia(icono: m.icono, color: m.color),
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
                      m.detalle,
                      style: TextStyle(
                        color: colores.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                texto: '+${m.puntos}',
                color: colores.recompensaTexto,
                fondo: colores.recompensaSuave,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (m.reclamada)
            Row(
              children: [
                Icon(Icons.check_circle, color: colores.primario, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Reclamada',
                  style: TextStyle(
                    color: colores.primarioTexto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else if (m.lista)
            BotonApp(
              key: Key('reclamar-${m.id}'),
              texto: 'Reclamar +${m.puntos} Rebin Points',
              variante: VarianteBoton.recompensa,
              estado: reclamando ? EstadoBoton.cargando : EstadoBoton.reposo,
              onPressed: reclamando ? null : onReclamar,
            )
          else
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: LinearProgressIndicator(
                      value: m.progreso,
                      minHeight: 8,
                      backgroundColor: colores.superficieAlta,
                      valueColor: AlwaysStoppedAnimation(colores.primario),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${m.actual}/${m.meta}'),
              ],
            ),
        ],
      ),
    );
  }
}

class _LogroCard extends StatelessWidget {
  final Logro logro;
  final bool reclamando;
  final VoidCallback onReclamar;

  const _LogroCard({
    required this.logro,
    required this.reclamando,
    required this.onReclamar,
  });

  static const _romanos = ['I', 'II', 'III', 'IV', 'V'];

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final l = logro;
    final sinLogro = l.nivel == 0;
    return Container(
      key: Key('logro-${l.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colores.borde),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: sinLogro ? 0.45 : 1,
            child: _Insignia(icono: l.icono, color: l.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (!sinLogro) ...[
                      const SizedBox(width: 8),
                      Pill(
                        texto: _romanos[l.nivel - 1],
                        color: colores.primarioTexto,
                        fondo: colores.primarioSuave,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l.descripcion,
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                if (l.reclamable)
                  BotonApp(
                    key: Key('reclamar-logro-${l.id}'),
                    texto:
                        'Reclamar nivel ${_romanos[l.nivel]} +${l.puntosSiguiente}',
                    variante: VarianteBoton.recompensa,
                    estado: reclamando
                        ? EstadoBoton.cargando
                        : EstadoBoton.reposo,
                    onPressed: reclamando ? null : onReclamar,
                  )
                else if (l.completo)
                  Text(
                    'Completo',
                    style: TextStyle(
                      color: colores.primarioTexto,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: LinearProgressIndicator(
                            value: l.progreso,
                            minHeight: 6,
                            backgroundColor: colores.superficieAlta,
                            valueColor: AlwaysStoppedAnimation(
                              colores.primario,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${l.actual}/${l.metaActual}'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
