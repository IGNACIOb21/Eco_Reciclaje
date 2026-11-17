import 'package:flutter/material.dart';

import '../data/guia_reciclaje.dart';
import '../models/material_type.dart';
import '../theme/app_theme.dart';
import 'guia_rapida_screen.dart';

/// Guía de reciclaje (pág. 14 del rediseño): un material a la vez, con qué sí
/// y qué no se recicla, cómo dejarlo y, en plástico, el número del triángulo.
/// "Escuchar las categorías" abre la Guía rápida, que las explica con voz.
class GuiaReciclajeScreen extends StatefulWidget {
  final TipoMaterial inicial;

  const GuiaReciclajeScreen({super.key, this.inicial = TipoMaterial.plastico});

  @override
  State<GuiaReciclajeScreen> createState() => _GuiaReciclajeScreenState();
}

class _GuiaReciclajeScreenState extends State<GuiaReciclajeScreen> {
  late GuiaMaterial _guia = _para(widget.inicial);

  static GuiaMaterial _para(TipoMaterial m) =>
      guiaReciclaje.firstWhere((g) => g.material == m);

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final g = _guia;
    return Scaffold(
      appBar: AppBar(title: const Text('Guía de reciclaje')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final m in guiaReciclaje)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ChipMaterial(
                        material: m.material,
                        seleccionado: m.material == g.material,
                        onTap: () => setState(() => _guia = m),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: Key('guia-${g.material.codigo}'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    g.intro,
                    style: TextStyle(color: colores.textoSecundario),
                  ),
                  const SizedBox(height: 14),
                  _Lista(si: true, titulo: 'Sí', elementos: g.si),
                  const SizedBox(height: 12),
                  _Lista(si: false, titulo: 'No', elementos: g.no),
                  const SizedBox(height: 12),
                  _Consejo(
                    icono: Icons.lightbulb_outline,
                    negrita: 'Antes de dejarlo: ',
                    texto: g.preparacion,
                  ),
                  if (g.material == TipoMaterial.plastico) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Mira el número del triángulo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _GrillaResinas(),
                  ],
                  const SizedBox(height: 12),
                  const _Consejo(
                    icono: Icons.local_fire_department_outlined,
                    negrita: 'Ojo: ',
                    texto: avisoQuemado,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      key: const Key('guia-escuchar'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GuiaRapidaScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.volume_up_outlined),
                      label: const Text('Escuchar las categorías'),
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

class _ChipMaterial extends StatelessWidget {
  final TipoMaterial material;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipMaterial({
    required this.material,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    // El naranja del plástico no da contraste con blanco: ícono oscuro.
    final oscuro =
        ThemeData.estimateBrightnessForColor(material.color) == Brightness.dark;
    return Semantics(
      button: true,
      selected: seleccionado,
      label: material.etiqueta,
      excludeSemantics: true,
      child: Material(
        color: seleccionado ? colores.primarioSuave : colores.superficie,
        shape: StadiumBorder(
          side: BorderSide(
            color: seleccionado ? colores.primarioTexto : colores.borde,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: Key('guia-chip-${material.codigo}'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: material.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    material.icono,
                    size: 18,
                    color: oscuro ? Colors.white : const Color(0xFF1E2B22),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  material.etiqueta,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta "Sí" (check verde) o "No" (cruz terracota) con sus ejemplos.
class _Lista extends StatelessWidget {
  final bool si;
  final String titulo;
  final List<String> elementos;

  const _Lista({
    required this.si,
    required this.titulo,
    required this.elementos,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final color = si ? colores.primarioTexto : colores.alertaTexto;
    return Container(
      key: Key(si ? 'guia-si' : 'guia-no'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(si ? Icons.check : Icons.close, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final e in elementos)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 6),
              child: Text(e),
            ),
        ],
      ),
    );
  }
}

class _Consejo extends StatelessWidget {
  final IconData icono;
  final String negrita;
  final String texto;

  const _Consejo({
    required this.icono,
    required this.negrita,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.primarioSuave,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: colores.primarioTexto),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: negrita,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: texto),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Los 7 tipos de plástico en dos columnas.
class _GrillaResinas extends StatelessWidget {
  const _GrillaResinas();

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < resinasPlastico.length; i += 2) {
      final par = resinasPlastico.skip(i).take(2).toList();
      filas.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _TarjetaResina(resina: par[0])),
                const SizedBox(width: 8),
                Expanded(
                  child: par.length > 1
                      ? _TarjetaResina(resina: par[1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: filas);
  }
}

class _TarjetaResina extends StatelessWidget {
  final ResinaPlastico resina;

  const _TarjetaResina({required this.resina});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final r = resina;
    final veredicto = r.seRecicla ? 'Sí se recicla' : 'No se recicla';
    return Semantics(
      label: 'Plástico ${r.numero}, ${r.sigla}: ${r.ejemplos}. $veredicto',
      excludeSemantics: true,
      child: Container(
        key: Key('resina-${r.numero}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colores.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colores.borde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TrianguloResina(numero: r.numero, color: colores.texto),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.sigla,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    r.ejemplos,
                    style: TextStyle(
                      color: colores.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    veredicto,
                    style: TextStyle(
                      color: r.seRecicla
                          ? colores.primarioTexto
                          : colores.alertaTexto,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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

/// Triángulo de flechas del código de resina, simplificado: contorno con el
/// número al centro.
class _TrianguloResina extends StatelessWidget {
  final int numero;
  final Color color;

  const _TrianguloResina({required this.numero, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 36,
    child: CustomPaint(
      painter: _PintorTriangulo(color),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: Text(
            '$numero',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );
}

class _PintorTriangulo extends CustomPainter {
  final Color color;

  _PintorTriangulo(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final ruta = Path()
      ..moveTo(size.width / 2, 2)
      ..lineTo(size.width - 2, size.height - 2)
      ..lineTo(2, size.height - 2)
      ..close();
    canvas.drawPath(ruta, trazo);
  }

  @override
  bool shouldRepaint(_PintorTriangulo anterior) => anterior.color != color;
}
