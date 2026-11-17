import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ilustración de fondo de la apertura: varias personas reciclando en la
/// parte de abajo de la pantalla, cada una echando algo a su contenedor.
///
/// Todo se dibuja en una escena de 390 × 230 que se escala al ancho de la
/// pantalla y se apoya en el borde inferior. [tMs] anima la entrada: las
/// personas suben y aparecen (0–600 ms) y cada objeto cae en su contenedor.
class PersonasReciclandoPainter extends CustomPainter {
  final double tMs;

  /// Opacidad general: la escena es fondo, no compite con el logo.
  final double intensidad;

  PersonasReciclandoPainter({required this.tMs, this.intensidad = 0.9});

  static const _anchoEscena = 390.0;
  static const _altoEscena = 230.0;
  static const _suelo = 205.0;

  static const _pelo = Color(0xFF3B2A20);
  static const _peloClaro = Color(0xFF8A5A2B);
  static const _pantalon = Color(0xFF34495E);
  static const _pantalonClaro = Color(0xFF5D6D7E);

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / _anchoEscena;
    final altoReal = _altoEscena * escala;
    canvas.save();
    canvas.translate(0, size.height - altoReal);
    canvas.scale(escala);

    final entrada = Curves.easeOutCubic.transform(
      (tMs / 600).clamp(0.0, 1.0),
    );
    canvas.translate(0, 24 * (1 - entrada));
    final alfa = intensidad * entrada;

    // Suelo: una loma suave de pasto.
    canvas.drawPath(
      Path()
        ..moveTo(0, _suelo - 4)
        ..quadraticBezierTo(_anchoEscena / 2, _suelo - 16, _anchoEscena, _suelo - 4)
        ..lineTo(_anchoEscena, _altoEscena + 40)
        ..lineTo(0, _altoEscena + 40)
        ..close(),
      Paint()..color = const Color(0xFF8BC79A).withValues(alpha: 0.55 * alfa),
    );

    // Contenedores: papel (azul), plástico (amarillo) y vidrio (verde).
    _contenedor(canvas, 112, const Color(0xFF2F6FB5), alfa);
    _contenedor(canvas, 214, const Color(0xFFE5A823), alfa);
    _contenedor(canvas, 300, const Color(0xFF2E8B57), alfa);

    // Árbol pequeño al fondo, a la izquierda.
    _arbol(canvas, 22, alfa);

    // 1. Mujer echando un papel al azul.
    final p1 = _persona(
      canvas,
      x: 62,
      alto: 118,
      mira: 1,
      piel: const Color(0xFFE8B98F),
      polera: const Color(0xFFE06D5A),
      pantalon: _pantalon,
      pelo: _pelo,
      peloLargo: true,
      brazoHacia: const Offset(94, 132),
      alfa: alfa,
      fase: 0,
    );
    _objetoCayendo(
      canvas,
      desde: p1,
      hasta: const Offset(112, 150),
      inicioMs: 500,
      dibujar: (c, o) => _papel(c, o, alfa),
    );

    // 2. Hombre echando una botella al amarillo.
    final p2 = _persona(
      canvas,
      x: 170,
      alto: 128,
      mira: 1,
      piel: const Color(0xFFA86B45),
      polera: const Color(0xFF3B82C4),
      pantalon: _pantalonClaro,
      pelo: _pelo,
      peloLargo: false,
      brazoHacia: const Offset(198, 122),
      alfa: alfa,
      fase: 1.3,
    );
    _objetoCayendo(
      canvas,
      desde: p2,
      hasta: const Offset(214, 150),
      inicioMs: 750,
      dibujar: (c, o) => _botella(c, o, alfa),
    );

    // 3. Niño con una lata, mirando al verde.
    final p3 = _persona(
      canvas,
      x: 262,
      alto: 84,
      mira: 1,
      piel: const Color(0xFFF2CDA8),
      polera: const Color(0xFFF2B33D),
      pantalon: _pantalon,
      pelo: _peloClaro,
      peloLargo: false,
      brazoHacia: const Offset(284, 140),
      alfa: alfa,
      fase: 2.1,
    );
    _objetoCayendo(
      canvas,
      desde: p3,
      hasta: const Offset(300, 150),
      inicioMs: 1000,
      dibujar: (c, o) => _frasco(c, o, alfa),
    );

    // 4. Mujer llegando con una caja, desde la derecha.
    final p4 = _persona(
      canvas,
      x: 352,
      alto: 116,
      mira: -1,
      piel: const Color(0xFF7A4B2A),
      polera: const Color(0xFF4C9F70),
      pantalon: _pantalonClaro,
      pelo: _pelo,
      peloLargo: true,
      brazoHacia: const Offset(330, 136),
      alfa: alfa,
      fase: 0.6,
    );
    _caja(canvas, p4 + const Offset(-6, 2), alfa);

    canvas.restore();
  }

  /// Dibuja una persona de pie sobre el suelo en [x] y devuelve dónde queda
  /// su mano (para lo que sostiene).
  Offset _persona(
    Canvas canvas, {
    required double x,
    required double alto,
    required double mira,
    required Color piel,
    required Color polera,
    required Color pantalon,
    required Color pelo,
    required bool peloLargo,
    required Offset brazoHacia,
    required double alfa,
    required double fase,
  }) {
    Color a(Color c) => c.withValues(alpha: c.a * alfa);
    // Un leve vaivén para que la escena respire.
    final vaiven = math.sin(tMs / 380 + fase) * 1.2;
    final u = alto / 120;
    final pie = _suelo - 6;
    final cadera = pie - 46 * u;
    final hombro = cadera - 40 * u + vaiven;
    final cabeza = hombro - 15 * u;

    final pierna = Paint()
      ..color = a(pantalon)
      ..strokeWidth = 10 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 5 * u, cadera), Offset(x - 7 * u, pie), pierna);
    canvas.drawLine(Offset(x + 5 * u, cadera), Offset(x + 8 * u, pie), pierna);

    // Torso.
    canvas.drawRRect(
      RRect.fromLTRBR(
        x - 13 * u,
        hombro - 2 * u,
        x + 13 * u,
        cadera + 4 * u,
        Radius.circular(9 * u),
      ),
      Paint()..color = a(polera),
    );

    // Brazo de atrás, relajado.
    final brazo = Paint()
      ..color = a(piel)
      ..strokeWidth = 7 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(x - 9 * u * mira, hombro + 4 * u),
      Offset(x - 12 * u * mira, cadera - 2 * u),
      brazo,
    );

    // Pelo largo detrás de la cabeza.
    if (peloLargo) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          x - 12 * u,
          cabeza - 10 * u,
          x + 12 * u,
          hombro + 10 * u,
          Radius.circular(10 * u),
        ),
        Paint()..color = a(pelo),
      );
    }

    // Cabeza y pelo.
    canvas.drawCircle(Offset(x, cabeza), 11 * u, Paint()..color = a(piel));
    canvas.drawArc(
      Rect.fromCircle(center: Offset(x, cabeza - 1 * u), radius: 11.5 * u),
      math.pi,
      math.pi,
      true,
      Paint()..color = a(pelo),
    );

    // Brazo de adelante, estirado hacia el contenedor.
    final hombroDelantero = Offset(x + 8 * u * mira, hombro + 4 * u);
    final dir = brazoHacia - hombroDelantero;
    final mano = hombroDelantero + dir / dir.distance * 30 * u;
    canvas.drawLine(hombroDelantero, mano, brazo);
    canvas.drawCircle(mano, 4 * u, Paint()..color = a(piel));
    return mano;
  }

  void _contenedor(Canvas canvas, double x, Color color, double alfa) {
    final c = color.withValues(alpha: alfa);
    const ancho = 46.0, alto = 58.0;
    final base = _suelo - 4;
    canvas.drawPath(
      Path()
        ..moveTo(x - ancho / 2, base - alto)
        ..lineTo(x + ancho / 2, base - alto)
        ..lineTo(x + ancho / 2 - 4, base - 3)
        ..quadraticBezierTo(x + ancho / 2 - 5, base, x + ancho / 2 - 8, base)
        ..lineTo(x - ancho / 2 + 8, base)
        ..quadraticBezierTo(x - ancho / 2 + 5, base, x - ancho / 2 + 4, base - 3)
        ..close(),
      Paint()..color = c,
    );
    // Tapa, un poco más oscura.
    canvas.drawRRect(
      RRect.fromLTRBR(
        x - ancho / 2 - 4,
        base - alto - 8,
        x + ancho / 2 + 4,
        base - alto + 1,
        const Radius.circular(4),
      ),
      Paint()..color = Color.lerp(c, Colors.black, 0.25)!,
    );
    // Símbolo de reciclaje simple en blanco.
    final simbolo = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * alfa)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final centro = Offset(x, base - alto / 2 + 2);
    for (var i = 0; i < 3; i++) {
      final a0 = -math.pi / 2 + i * 2 * math.pi / 3 + 0.35;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: 9),
        a0,
        1.4,
        false,
        simbolo,
      );
    }
  }

  void _arbol(Canvas canvas, double x, double alfa) {
    canvas.drawRect(
      Rect.fromLTWH(x - 3, _suelo - 50, 6, 44),
      Paint()..color = const Color(0xFF7A4E2D).withValues(alpha: 0.7 * alfa),
    );
    final copa = Paint()
      ..color = const Color(0xFF4FA36A).withValues(alpha: 0.75 * alfa);
    canvas.drawCircle(Offset(x, _suelo - 62), 20, copa);
    canvas.drawCircle(Offset(x - 13, _suelo - 50), 13, copa);
    canvas.drawCircle(Offset(x + 13, _suelo - 50), 13, copa);
  }

  /// Un objeto que sale de la mano y cae en arco dentro del contenedor; luego
  /// vuelve a aparecer en la mano y repite, mientras dure la apertura.
  void _objetoCayendo(
    Canvas canvas, {
    required Offset desde,
    required Offset hasta,
    required double inicioMs,
    required void Function(Canvas, Offset) dibujar,
  }) {
    const ciclo = 1500.0, vuelo = 700.0;
    if (tMs < inicioMs) {
      dibujar(canvas, desde);
      return;
    }
    final t = (tMs - inicioMs) % ciclo;
    if (t > vuelo) {
      // Pausa: ya cayó; reaparece en la mano al final del ciclo.
      if (t > ciclo - 250) dibujar(canvas, desde);
      return;
    }
    final p = Curves.easeIn.transform(t / vuelo);
    final control = Offset((desde.dx + hasta.dx) / 2, desde.dy - 28);
    final pos = Offset(
      _bezier(desde.dx, control.dx, hasta.dx, p),
      _bezier(desde.dy, control.dy, hasta.dy, p),
    );
    dibujar(canvas, pos);
  }

  static double _bezier(double a, double b, double c, double t) =>
      (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;

  void _papel(Canvas canvas, Offset o, double alfa) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: 12, height: 14),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: alfa),
    );
    final linea = Paint()
      ..color = const Color(0xFF9AA5B1).withValues(alpha: alfa)
      ..strokeWidth = 1.2;
    for (final dy in [-3.0, 0.0, 3.0]) {
      canvas.drawLine(o + Offset(-4, dy), o + Offset(4, dy), linea);
    }
  }

  void _botella(Canvas canvas, Offset o, double alfa) {
    final c = const Color(0xFF7FC4E8).withValues(alpha: alfa);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o + const Offset(0, 2), width: 9, height: 16),
        const Radius.circular(3),
      ),
      Paint()..color = c,
    );
    canvas.drawRect(
      Rect.fromCenter(center: o + const Offset(0, -8), width: 4, height: 5),
      Paint()..color = const Color(0xFF1F6FA8).withValues(alpha: alfa),
    );
  }

  void _frasco(Canvas canvas, Offset o, double alfa) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: 10, height: 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF9ED9B0).withValues(alpha: alfa),
    );
    canvas.drawRect(
      Rect.fromCenter(center: o + const Offset(0, -7.5), width: 8, height: 3),
      Paint()..color = const Color(0xFF6B7B8C).withValues(alpha: alfa),
    );
  }

  void _caja(Canvas canvas, Offset o, double alfa) {
    final caja = Rect.fromCenter(center: o, width: 26, height: 20);
    canvas.drawRect(
      caja,
      Paint()..color = const Color(0xFFC9955C).withValues(alpha: alfa),
    );
    canvas.drawLine(
      caja.topCenter,
      caja.bottomCenter,
      Paint()
        ..color = const Color(0xFFE8C48E).withValues(alpha: alfa)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(PersonasReciclandoPainter old) =>
      old.tMs != tMs || old.intensidad != intensidad;
}
