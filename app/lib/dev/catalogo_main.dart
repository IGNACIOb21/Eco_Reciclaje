// Catálogo del sistema de diseño: cada componente en claro y Modo Eco, para
// compararlo con el lienzo en el teléfono. No forma parte de la app:
//   flutter run -t lib/dev/catalogo_main.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tipografia.dart';
import '../widgets/anillo_meta.dart';
import '../widgets/barra_nivel.dart';
import '../widgets/boton_app.dart';
import '../widgets/chip_rebin.dart';
import '../widgets/contador_puntos.dart';
import '../widgets/puntos_que_vuelan.dart';
import '../widgets/toast_rebin.dart';
import '../theme/elevacion.dart';

void main() => runApp(const _Catalogo());

class _Catalogo extends StatefulWidget {
  const _Catalogo();

  @override
  State<_Catalogo> createState() => _CatalogoState();
}

class _CatalogoState extends State<_Catalogo> {
  bool _eco = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo Rebin',
      theme: _eco ? AppTheme.eco : AppTheme.light,
      home: _Pantalla(
        eco: _eco,
        alCambiarTema: () => setState(() => _eco = !_eco),
      ),
    );
  }
}

class _Pantalla extends StatefulWidget {
  final bool eco;
  final VoidCallback alCambiarTema;

  const _Pantalla({required this.eco, required this.alCambiarTema});

  @override
  State<_Pantalla> createState() => _PantallaState();
}

class _PantallaState extends State<_Pantalla> {
  final _origen = GlobalKey();
  final _destino = GlobalKey();
  int _puntos = 524;
  double _nivel = 0.81;
  bool _meta = false;
  String _chip = 'Vidrio';
  EstadoBoton _vivo = EstadoBoton.reposo;

  void _sumar() {
    PuntosQueVuelan.lanzar(
      context,
      desde: _origen,
      hasta: _destino,
      texto: '+5 Rebin Points',
      alLlegar: () {
        if (!mounted) return;
        setState(() {
          _puntos += 5;
          _nivel = (_nivel + 0.05).clamp(0, 1);
        });
      },
    );
  }

  Future<void> _probarBoton() async {
    setState(() => _vivo = EstadoBoton.cargando);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _vivo = EstadoBoton.exito);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _vivo = EstadoBoton.reposo);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          Switch(value: widget.eco, onChanged: (_) => widget.alCambiarTema()),
          Center(
            child: Text('Eco', style: TextStyle(color: c.texto)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Seccion('Tipografía'),
          Text(
            '¡Subiste a Pro!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Enjuaga la botella y aplástala antes de dejarla.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            '117 Rebin Points · 38 objetos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFeatures: Tipografia.cifras,
              color: c.texto,
            ),
          ),
          _Seccion('Botones'),
          for (final v in VarianteBoton.values) ...[
            Row(
              children: [
                Expanded(
                  child: BotonApp(texto: v.name, variante: v, onPressed: () {}),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BotonApp(texto: v.name, variante: v, onPressed: null),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          BotonApp(
            texto: 'Reclamar +10 Rebin Points',
            textoCargando: 'Reclamando…',
            textoExito: '+10 sumados',
            variante: VarianteBoton.recompensa,
            estado: _vivo,
            onPressed: _probarBoton,
          ),
          _Seccion('Contador, vuelo y barra de nivel'),
          Row(
            children: [
              KeyedSubtree(
                key: _destino,
                child: ContadorPuntos(puntos: _puntos),
              ),
              const Spacer(),
              KeyedSubtree(
                key: _origen,
                child: BotonApp(
                  texto: 'Ganar +5',
                  onPressed: _sumar,
                ).sizedBox(150),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BarraNivel(progreso: _nivel),
          const SizedBox(height: 4),
          Text(
            'Aprendiz · te faltan ${(600 - 200 - (_nivel * 400)).round()} para Pro',
            style: TextStyle(color: c.textoSecundario),
          ),
          _Seccion('Anillo de meta'),
          Row(
            children: [
              const AnilloMeta(progreso: 0, etiqueta: '0/1'),
              const SizedBox(width: 16),
              AnilloMeta(
                progreso: _meta ? 1 : 0,
                etiqueta: _meta ? '1/1' : '0/1',
              ),
              const SizedBox(width: 16),
              BotonApp(
                texto: 'Completar',
                variante: VarianteBoton.secundario,
                onPressed: () => setState(() => _meta = !_meta),
              ).sizedBox(150),
            ],
          ),
          _Seccion('Chips y aviso'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in ['Vidrio', 'Papel', 'Plástico', 'Latas'])
                ChipRebin(
                  texto: n,
                  seleccionado: _chip == n,
                  onTap: () => setState(() => _chip = n),
                ),
            ],
          ),
          const SizedBox(height: 12),
          BotonApp(
            texto: 'Mostrar aviso',
            variante: VarianteBoton.terciario,
            onPressed: () => ToastRebin.mostrar(
              context,
              '¡Bien!',
              textoDorado: '+5 Rebin Points',
            ),
          ),
          _Seccion('Elevación'),
          Row(
            children: [
              for (var n = 0; n <= 3; n++)
                Expanded(
                  child: Container(
                    height: 72,
                    margin: const EdgeInsets.only(right: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: n == 0 ? c.fondo : c.superficie,
                      borderRadius: BorderRadius.circular(16),
                      border: n == 0 ? Border.all(color: c.borde) : null,
                      boxShadow: context.sombra(n),
                    ),
                    child: Text('e$n', style: TextStyle(color: c.texto)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;

  const _Seccion(this.titulo);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
  );
}

extension on Widget {
  Widget sizedBox(double ancho) => SizedBox(width: ancho, child: this);
}
