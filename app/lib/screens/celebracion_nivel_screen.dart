import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/nivel.dart';
import '../services/haptica.dart';
import '../theme/movimiento.dart';
import '../widgets/boton_app.dart';

/// Abre la celebración a pantalla completa, con un fundido.
Future<void> mostrarCelebracionNivel(
  BuildContext context, {
  required Nivel nivel,
  required List<Nivel> niveles,
  required int acumulado,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Movimiento.transicion,
      reverseTransitionDuration: Movimiento.transicionSalir,
      pageBuilder: (_, _, _) => CelebracionNivelScreen(
        nivel: nivel,
        niveles: niveles,
        acumulado: acumulado,
      ),
      transitionsBuilder: (_, animacion, _, hijo) =>
          FadeTransition(opacity: animacion, child: hijo),
    ),
  );
}

/// La única celebración grande de la app: subir de nivel (lienzo
/// `FlujoNivel.dc.html`). Insignia con rebote, 12 partículas, el nombre del
/// nivel y lo que sigue. Tocar en cualquier parte adelanta la animación;
/// "Seguir" la cierra. Con "reducir animaciones" todo aparece de una vez.
class CelebracionNivelScreen extends StatefulWidget {
  final Nivel nivel;
  final List<Nivel> niveles;
  final int acumulado;

  const CelebracionNivelScreen({
    super.key,
    required this.nivel,
    required this.niveles,
    required this.acumulado,
  });

  // Paleta propia de la celebración (el verde bosque oscuro del lienzo), igual
  // en todos los temas: es un momento aparte del resto de la app.
  static const fondo = Color(0xFF0F3A1E);
  static const tarjeta = Color(0xFF16472A);
  static const texto = Color(0xFFECEFE5);
  static const textoSecundario = Color(0xFFA9C8B0);
  static const hoja = Color(0xFF6CC487);
  static const dorado = Color(0xFFE2B85C);

  /// Una frase por nivel; los que vengan de la base con otro nombre usan la
  /// genérica.
  static String frase(Nivel n) => switch (n.nombreCorto) {
    'Aprendiz' => 'Ya sabes lo básico. Cada reciclaje cuenta.',
    'Pro' => 'Ya reciclas como alguien que sabe lo que hace.',
    'Experto' => 'Tu barrio recicla mejor gracias a ti.',
    'Maestro' => 'Llegaste a lo más alto. Gracias por cuidar tu barrio.',
    _ => 'Sigue así: cada reciclaje cuenta.',
  };

  @override
  State<CelebracionNivelScreen> createState() => _CelebracionNivelScreenState();
}

class _CelebracionNivelScreenState extends State<CelebracionNivelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    Haptica.doble();
    if (Movimiento.reducido(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Tramo [inicio, fin] (en ms) de la animación, de 0 a 1.
  Animation<double> _tramo(int inicio, int fin, [Curve curva = Curves.linear]) {
    const total = 1400;
    return CurvedAnimation(
      parent: _c,
      curve: Interval(inicio / total, fin / total, curve: curva),
    );
  }

  Widget _subir(Widget hijo, int inicio) {
    final t = _tramo(inicio, inicio + 280, Movimiento.entrar);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(t),
        child: hijo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nivel;
    final numero =
        widget.niveles.indexWhere((x) => x.puntosMinimos == n.puntosMinimos) +
        1;
    final siguiente = n.siguienteEn(widget.niveles);
    final insignia = _tramo(120, 920, Movimiento.rebote);
    return Scaffold(
      backgroundColor: CelebracionNivelScreen.fondo,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tocar en cualquier parte deja todo a la vista.
        onTap: () => _c.value = 1,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!Movimiento.reducido(context))
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _c,
                            builder: (_, _) => CustomPaint(
                              size: const Size(260, 260),
                              painter: _Particulas(
                                (_c.value * 1400 / 1000).clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                      ScaleTransition(
                        scale: insignia,
                        child: _Insignia(numero: numero),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _subir(
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '¡Subiste a ${n.nombreCorto}!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: CelebracionNivelScreen.texto),
                    ),
                  ),
                  520,
                ),
                const SizedBox(height: 8),
                _subir(
                  Text(
                    '${n.puntosMinimos} Rebin Points. '
                    '${CelebracionNivelScreen.frase(n)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CelebracionNivelScreen.textoSecundario,
                      fontSize: 15,
                    ),
                  ),
                  600,
                ),
                const SizedBox(height: 20),
                _subir(
                  Container(
                    key: const Key('celebracion-siguiente'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CelebracionNivelScreen.tarjeta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: CelebracionNivelScreen.hoja,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            siguiente == null
                                ? Icons.emoji_events_outlined
                                : Icons.arrow_forward,
                            size: 20,
                            color: CelebracionNivelScreen.fondo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siguiente == null
                                    ? 'Nivel máximo'
                                    : 'Próximo: ${siguiente.nombreCorto}',
                                style: const TextStyle(
                                  color: CelebracionNivelScreen.texto,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                siguiente == null
                                    ? 'No hay más niveles. Tu planta sigue '
                                          'creciendo igual.'
                                    : 'Te faltan '
                                          '${siguiente.puntosMinimos - widget.acumulado}'
                                          ' Rebin Points. Sin apuro: cada '
                                          'reciclaje cuenta.',
                                style: const TextStyle(
                                  color: CelebracionNivelScreen.textoSecundario,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  680,
                ),
                const Spacer(),
                _subir(
                  SizedBox(
                    width: double.infinity,
                    child: BotonApp(
                      key: const Key('celebracion-seguir'),
                      texto: 'Seguir',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  820,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Insignia del nivel: disco verde con anillo dorado y el número.
class _Insignia extends StatelessWidget {
  final int numero;

  const _Insignia({required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CelebracionNivelScreen.dorado.withValues(alpha: 0.22),
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CelebracionNivelScreen.hoja,
          border: Border.all(color: CelebracionNivelScreen.dorado, width: 4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco,
              color: CelebracionNivelScreen.fondo,
              size: 34,
            ),
            Text(
              'nivel $numero',
              style: const TextStyle(
                color: CelebracionNivelScreen.fondo,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 12 partículas que salen desde la insignia y se desvanecen, en una capa.
class _Particulas extends CustomPainter {
  final double t;

  _Particulas(this.t);

  static const _colores = [
    CelebracionNivelScreen.dorado,
    CelebracionNivelScreen.hoja,
    CelebracionNivelScreen.texto,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final centro = size.center(Offset.zero);
    final avance = Curves.easeOutCubic.transform(t);
    final opacidad = 1 - Curves.easeIn.transform(t);
    for (var i = 0; i < 12; i++) {
      final angulo = i / 12 * math.pi * 2;
      final distancia = (96 + (i % 3) * 18) * avance;
      final p = centro + Offset(math.cos(angulo), math.sin(angulo)) * distancia;
      canvas.drawCircle(
        p,
        i % 3 == 0 ? 4 : 2.5,
        Paint()..color = _colores[i % 3].withValues(alpha: opacidad),
      );
    }
  }

  @override
  bool shouldRepaint(_Particulas v) => v.t != t;
}
