import 'package:flutter/material.dart';

import '../models/material_type.dart';
import '../models/perfil_local.dart';
import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import '../widgets/boton_app.dart';
import '../widgets/planta_racha.dart';

/// Avatares que se ofrecen en la última lámina: ícono y color del set fijo
/// del perfil local (los mismos de Personalizar perfil).
const avataresOnboarding = [
  (AvatarIcono.hoja, 0),
  (AvatarIcono.reciclaje, 1),
  (AvatarIcono.sol, 2),
  (AvatarIcono.arbol, 3),
  (AvatarIcono.mascota, 4),
  (AvatarIcono.corazon, 5),
];

/// Las 3 láminas de presentación del primer inicio (pág. 20 del rediseño;
/// textos de `Onboarding.dc.html`): escanear, el mapa y la planta con la
/// elección del avatar. "Saltar" lleva a la última lámina, para que igual se
/// elija avatar; "Empezar" entrega el avatar elegido.
class OnboardingScreen extends StatefulWidget {
  final void Function(AvatarIcono icono, int colorIndex) onTerminar;

  const OnboardingScreen({super.key, required this.onTerminar});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _laminas = [
    (
      titulo: 'Apunta y sabrás si se recicla',
      texto:
          'Saca una foto a cualquier envase. En un par de segundos te decimos '
          'si va, dónde va y cómo dejarlo.',
    ),
    (
      titulo: 'Encuentra dónde dejarlo',
      texto:
          'Puntos limpios y contenedores cerca de ti, con el estado que '
          'reportan tus vecinos. Tú también puedes avisar.',
    ),
    (
      titulo: 'Haz crecer tu planta',
      texto:
          'Cada cosa que reciclas suma Rebin Points y una hoja. Elige cómo te '
          'verán en tu barrio:',
    ),
  ];

  final _paginas = PageController();
  int _pagina = 0;
  int _avatar = 0;

  bool get _ultima => _pagina == _laminas.length - 1;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _irA(int pagina) {
    _paginas.animateToPage(
      pagina,
      duration: Movimiento.dur(context, Movimiento.transicion),
      curve: Movimiento.entrar,
    );
  }

  void _siguiente() {
    if (_ultima) {
      final (icono, color) = avataresOnboarding[_avatar];
      widget.onTerminar(icono, color);
    } else {
      _irA(_pagina + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      backgroundColor: colores.fondo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    'rebin',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: colores.primarioTexto),
                  ),
                  const Spacer(),
                  // En la última lámina no hay nada que saltar.
                  SizedBox(
                    height: 48,
                    child: _ultima
                        ? null
                        : TextButton(
                            key: const Key('onboarding-saltar'),
                            onPressed: () => _irA(_laminas.length - 1),
                            child: const Text('Saltar'),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _paginas,
                onPageChanged: (p) => setState(() => _pagina = p),
                children: [
                  for (final (i, l) in _laminas.indexed)
                    _Lamina(
                      titulo: l.titulo,
                      texto: l.texto,
                      ilustracion: switch (i) {
                        0 => const _IlustracionEscanear(),
                        1 => const _IlustracionMapa(),
                        _ => const _IlustracionPlanta(),
                      },
                      extra: i == _laminas.length - 1
                          ? _ElegirAvatar(
                              elegido: _avatar,
                              onElegir: (a) => setState(() => _avatar = a),
                            )
                          : null,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Semantics(
                    label: 'Paso ${_pagina + 1} de ${_laminas.length}',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _laminas.length; i++)
                          AnimatedContainer(
                            duration: Movimiento.dur(
                              context,
                              Movimiento.transicion,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _pagina ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _pagina
                                  ? colores.primario
                                  : colores.borde,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: BotonApp(
                      key: const Key('onboarding-siguiente'),
                      texto: _ultima ? 'Empezar' : 'Siguiente',
                      onPressed: _siguiente,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lamina extends StatelessWidget {
  final String titulo;
  final String texto;
  final Widget ilustracion;
  final Widget? extra;

  const _Lamina({
    required this.titulo,
    required this.texto,
    required this.ilustracion,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: colores.superficie,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExcludeSemantics(child: ilustracion),
        ),
        const SizedBox(height: 24),
        Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          texto,
          style: TextStyle(color: colores.textoSecundario, fontSize: 15),
        ),
        if (extra != null) ...[const SizedBox(height: 16), extra!],
      ],
    );
  }
}

/// Botella con las esquinas de escáner que respiran (quietas con "reducir
/// animaciones").
class _IlustracionEscanear extends StatefulWidget {
  const _IlustracionEscanear();

  @override
  State<_IlustracionEscanear> createState() => _IlustracionEscanearState();
}

class _IlustracionEscanearState extends State<_IlustracionEscanear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Movimiento.respirar,
    lowerBound: 0.94,
    upperBound: 1.0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.reducido(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Center(
      child: SizedBox(
        width: 190,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(70, 170),
              painter: _PintorBotella(
                cuerpo: TipoMaterial.plastico.color.withValues(alpha: 0.35),
                etiqueta: colores.primario,
                borde: colores.texto.withValues(alpha: 0.5),
              ),
            ),
            RepaintBoundary(
              child: ScaleTransition(
                scale: _c,
                child: CustomPaint(
                  size: const Size(190, 210),
                  painter: _PintorEsquinas(colores.primarioTexto),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PintorBotella extends CustomPainter {
  final Color cuerpo;
  final Color etiqueta;
  final Color borde;

  _PintorBotella({
    required this.cuerpo,
    required this.etiqueta,
    required this.borde,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tapa = RRect.fromLTRBR(
      w * 0.3,
      0,
      w * 0.7,
      h * 0.08,
      const Radius.circular(3),
    );
    final cuerpoRuta = Path()
      ..moveTo(w * 0.35, h * 0.08)
      ..lineTo(w * 0.65, h * 0.08)
      ..quadraticBezierTo(w * 0.65, h * 0.2, w, h * 0.3)
      ..lineTo(w, h * 0.94)
      ..quadraticBezierTo(w, h, w * 0.9, h)
      ..lineTo(w * 0.1, h)
      ..quadraticBezierTo(0, h, 0, h * 0.94)
      ..lineTo(0, h * 0.3)
      ..quadraticBezierTo(w * 0.35, h * 0.2, w * 0.35, h * 0.08)
      ..close();
    canvas.drawPath(cuerpoRuta, Paint()..color = cuerpo);
    canvas.drawRect(
      Rect.fromLTRB(0, h * 0.5, w, h * 0.68),
      Paint()..color = etiqueta,
    );
    final trazo = Paint()
      ..color = borde
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(cuerpoRuta, trazo);
    canvas.drawRRect(tapa, Paint()..color = etiqueta);
  }

  @override
  bool shouldRepaint(_PintorBotella v) =>
      v.cuerpo != cuerpo || v.etiqueta != etiqueta || v.borde != borde;
}

class _PintorEsquinas extends CustomPainter {
  final Color color;

  _PintorEsquinas(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const l = 34.0;
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final ruta = Path()
      ..moveTo(3, l)
      ..lineTo(3, 3)
      ..lineTo(l, 3)
      ..moveTo(w - l, 3)
      ..lineTo(w - 3, 3)
      ..lineTo(w - 3, l)
      ..moveTo(w - 3, h - l)
      ..lineTo(w - 3, h - 3)
      ..lineTo(w - l, h - 3)
      ..moveTo(l, h - 3)
      ..lineTo(3, h - 3)
      ..lineTo(3, h - l);
    canvas.drawPath(ruta, p);
  }

  @override
  bool shouldRepaint(_PintorEsquinas v) => v.color != color;
}

/// Un trozo de mapa con calles, un parque y pines de materiales.
class _IlustracionMapa extends StatelessWidget {
  const _IlustracionMapa();

  static const _pines = [
    (0.15, 0.2, TipoMaterial.vidrio),
    (0.62, 0.55, TipoMaterial.papel),
    (0.35, 0.68, TipoMaterial.plastico),
    (0.75, 0.18, TipoMaterial.latas),
    (0.12, 0.82, TipoMaterial.pilas),
  ];

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return LayoutBuilder(
      builder: (context, caja) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PintorMapa(
                calle: colores.fondo,
                parque: colores.primarioSuave,
              ),
            ),
          ),
          for (final (x, y, m) in _pines)
            Positioned(
              left: caja.maxWidth * x,
              top: caja.maxHeight * y - 18,
              child: _Pin(material: m),
            ),
        ],
      ),
    );
  }
}

class _PintorMapa extends CustomPainter {
  final Color calle;
  final Color parque;

  _PintorMapa({required this.calle, required this.parque});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromLTRBR(
        size.width * 0.45,
        size.height * 0.1,
        size.width * 0.9,
        size.height * 0.42,
        const Radius.circular(12),
      ),
      Paint()..color = parque,
    );
    final p = Paint()
      ..color = calle
      ..strokeWidth = 12;
    for (final f in [0.3, 0.6]) {
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f - 30),
        p,
      );
    }
    for (final f in [0.3, 0.7]) {
      canvas.drawLine(
        Offset(size.width * f, 0),
        Offset(size.width * f + 20, size.height),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorMapa v) => v.calle != calle || v.parque != parque;
}

class _Pin extends StatelessWidget {
  final TipoMaterial material;

  const _Pin({required this.material});

  @override
  Widget build(BuildContext context) {
    final oscuro =
        ThemeData.estimateBrightnessForColor(material.color) == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: material.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Icon(
        material.icono,
        size: 18,
        color: oscuro ? Colors.white : const Color(0xFF1E2B22),
      ),
    );
  }
}

/// La planta de la racha con el primer nivel por delante.
class _IlustracionPlanta extends StatelessWidget {
  const _IlustracionPlanta();

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const PlantaRacha(dias: 3, tamano: 150),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colores.primarioSuave,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'Novato · Aprendiz a 200',
            style: TextStyle(
              color: colores.primarioTexto,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ElegirAvatar extends StatelessWidget {
  final int elegido;
  final ValueChanged<int> onElegir;

  const _ElegirAvatar({required this.elegido, required this.onElegir});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, (icono, color)) in avataresOnboarding.indexed)
          Semantics(
            button: true,
            selected: i == elegido,
            label: 'Avatar ${i + 1}',
            excludeSemantics: true,
            child: GestureDetector(
              key: Key('onboarding-avatar-$i'),
              onTap: () => onElegir(i),
              child: AnimatedContainer(
                duration: Movimiento.dur(context, Movimiento.micro),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: coloresAvatar[color],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == elegido ? colores.primarioTexto : colores.fondo,
                    width: 3,
                  ),
                ),
                child: Icon(icono.icono, color: Colors.white, size: 26),
              ),
            ),
          ),
      ],
    );
  }
}
