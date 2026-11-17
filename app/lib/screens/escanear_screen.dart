import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../escaneo/clasificador_escaneo.dart';
import '../escaneo/escaneo_repository.dart';
import '../escaneo/info_clase.dart';
import '../escaneo/resultado_escaneo.dart';
import '../models/material_type.dart';
import '../state/usuario_controller.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import '../widgets/boton_app.dart';
import '../widgets/mensaje_error.dart';
import '../widgets/pill.dart';

/// Escaneo con el modelo de Joaquín: saca o elige una foto, el modelo TFLite
/// (en el teléfono) dice qué material es y el usuario puede registrarlo como
/// reciclaje para sumar Rebin Points.
///
/// El modelo se carga recién al primer escaneo: así abrir la pantalla es
/// inmediato y los tests no necesitan la librería nativa.
class EscanearScreen extends StatefulWidget {
  /// Vuelve al mapa filtrado por el material reconocido (null si el mapa no
  /// tiene ese material como filtro).
  final void Function(TipoMaterial? material) onVerEnMapa;

  final EscaneoRepository? repositorio;

  const EscanearScreen({
    super.key,
    required this.onVerEnMapa,
    this.repositorio,
  });

  @override
  State<EscanearScreen> createState() => _EscanearScreenState();
}

class _EscanearScreenState extends State<EscanearScreen>
    with SingleTickerProviderStateMixin {
  static const _fondo = Color(0xFF0B1A12);
  static const _lima = Color(0xFFA8DB3C);

  /// Barrido de la línea del visor mientras se analiza la foto.
  late final AnimationController _barrido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  final _picker = ImagePicker();
  late final EscaneoRepository _repositorio =
      widget.repositorio ?? escaneoPorDefecto();
  ClasificadorEscaneo? _clasificador;

  File? _foto;
  ResultadoEscaneo? _resultado;

  /// Material elegido: el que propone el modelo o el que corrige el usuario.
  InfoClase? _elegida;
  String? _error;
  bool _analizando = false;
  EstadoBoton _registro = EstadoBoton.reposo;

  @override
  void dispose() {
    _clasificador?.cerrar();
    _barrido.dispose();
    super.dispose();
  }

  Future<XFile?> _elegirFoto(ImageSource origen) async {
    try {
      // La foto se reduce al elegirla: una de 12 MP tarda mucho en
      // decodificarse y el modelo solo usa 224x224.
      return await _picker.pickImage(
        source: origen,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
    } catch (e) {
      debugPrint('EscanearScreen: no se pudo elegir la foto ($e)');
      if (mounted) {
        setState(() {
          _error = origen == ImageSource.camera
              ? 'No se pudo abrir la cámara. Revisa el permiso en Ajustes.'
              : 'No se pudo abrir la galería.';
        });
      }
      return null;
    }
  }

  Future<void> _escanear(ImageSource origen) async {
    if (_analizando) return;
    final elegido = await _elegirFoto(origen);
    if (elegido == null || !mounted) return;

    setState(() {
      _foto = File(elegido.path);
      _resultado = null;
      _elegida = null;
      _error = null;
      _analizando = true;
      _registro = EstadoBoton.reposo;
    });
    _barrido.repeat(reverse: true);
    try {
      final bytes = await elegido.readAsBytes();
      final clasificador = _clasificador ??= await ClasificadorEscaneo.cargar();
      final resultado = await clasificador.clasificar(bytes);
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _elegida = resultado.confianza == Confianza.baja
            ? null
            : resultado.mejor.info;
      });
    } catch (e) {
      debugPrint('EscanearScreen: falló la clasificación ($e)');
      if (mounted) {
        setState(() => _error = 'No pude analizar la foto. Intenta con otra.');
      }
    } finally {
      if (mounted) {
        _barrido.stop();
        setState(() => _analizando = false);
      }
    }
  }

  Future<void> _registrar() async {
    final elegida = _elegida;
    if (elegida == null || elegida.categoria.isEmpty) return;
    final usuario = context
        .getInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    setState(() => _registro = EstadoBoton.cargando);
    try {
      final r = await _repositorio.registrar(
        categoria: elegida.categoria,
        confianza: _resultado?.mejor.probabilidad,
      );
      if (!mounted) return;
      setState(() => _registro = EstadoBoton.exito);
      mostrarSnackbar(
        context,
        '¡Bien! +${r.puntos} Rebin Points. Ahora tienes ${r.saldo}.',
      );
      usuario?.cargar();
    } on EscaneoException catch (e) {
      if (!mounted) return;
      setState(() => _registro = EstadoBoton.reposo);
      mostrarSnackbar(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final resultado = _resultado;
    final alto = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: _fondo,
      body: Stack(
        children: [
          Positioned(
            top: 120,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x8C12804B), Color(0x0012804B)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      _BotonVidrio(
                        icono: Icons.close,
                        etiqueta: 'Cerrar',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: Center(child: _ChipVidrio('Escanear objeto')),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _Visor(
                      foto: _foto,
                      analizando: _analizando,
                      barrido: _barrido,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: alto * 0.55),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.superficie.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x59000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (resultado == null) ...[
                            Text(
                              'Saca una foto del objeto (solo, con buena luz) '
                              'y te digo de qué material es y dónde reciclarlo.',
                              style: TextStyle(
                                color: c.textoSecundario,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (_error != null) MensajeError(texto: _error!),
                          if (resultado != null) ...[
                            _TarjetaResultado(
                              resultado: resultado,
                              elegida: _elegida,
                              onElegir: (info) => setState(() {
                                _elegida = info;
                                _registro = EstadoBoton.reposo;
                              }),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_elegida != null) ...[
                              BotonApp(
                                texto: 'Registrar reciclaje',
                                icono: Icons.recycling,
                                variante: VarianteBoton.recompensa,
                                estado: _registro,
                                textoCargando: 'Registrando…',
                                textoExito: 'Registrado',
                                onPressed: _registrar,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              BotonApp(
                                texto: 'Ver dónde reciclarlo',
                                icono: Icons.map_outlined,
                                variante: VarianteBoton.secundario,
                                onPressed: () =>
                                    widget.onVerEnMapa(_elegida!.material),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                          BotonApp(
                            texto: _foto == null
                                ? 'Tomar foto'
                                : 'Tomar otra foto',
                            icono: Icons.photo_camera_outlined,
                            onPressed: _analizando
                                ? null
                                : () => _escanear(ImageSource.camera),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          BotonApp(
                            texto: 'Elegir de la galería',
                            icono: Icons.photo_library_outlined,
                            variante: VarianteBoton.secundario,
                            onPressed: _analizando
                                ? null
                                : () => _escanear(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ),
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

/// Botón redondo de vidrio sobre el fondo oscuro del escáner.
class _BotonVidrio extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  const _BotonVidrio({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0x24FFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Icon(icono, color: Colors.white),
        ),
      ),
    );
  }
}

/// Etiqueta de vidrio con el título de la pantalla.
class _ChipVidrio extends StatelessWidget {
  final String texto;

  const _ChipVidrio(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x40FFFFFF)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Visor futurista: esquinas lima, línea de barrido con brillo y, cuando hay
/// foto, la foto dentro del marco.
class _Visor extends StatelessWidget {
  final File? foto;
  final bool analizando;
  final Animation<double> barrido;

  const _Visor({
    required this.foto,
    required this.analizando,
    required this.barrido,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (foto != null)
            Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(foto!, fit: BoxFit.cover),
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.center_focus_weak,
                size: 56,
                color: Color(0x40FFFFFF),
              ),
            ),
          if (analizando)
            Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Align(
                  alignment: Alignment(0, 0.8),
                  child: Text(
                    'Analizando…',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          IgnorePointer(
            child: CustomPaint(
              painter: _EsquinasPainter(color: _EscanearScreenState._lima),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: barrido,
              builder: (context, _) => Align(
                alignment: Alignment(
                  0,
                  analizando ? barrido.value * 1.7 - 0.85 : 0,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  height: 3,
                  decoration: BoxDecoration(
                    color: _EscanearScreenState._lima,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x99A8DB3C),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EsquinasPainter extends CustomPainter {
  final Color color;

  _EsquinasPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const largo = 46.0;
    const r = 18.0;
    final rect = Offset.zero & size;
    for (final (esquina, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(esquina.dx, esquina.dy + dy * largo)
          ..lineTo(esquina.dx, esquina.dy + dy * r)
          ..quadraticBezierTo(
            esquina.dx,
            esquina.dy,
            esquina.dx + dx * r,
            esquina.dy,
          )
          ..lineTo(esquina.dx + dx * largo, esquina.dy),
        trazo,
      );
    }
  }

  @override
  bool shouldRepaint(_EsquinasPainter anterior) => anterior.color != color;
}

class _TarjetaResultado extends StatelessWidget {
  final ResultadoEscaneo resultado;
  final InfoClase? elegida;
  final ValueChanged<InfoClase> onElegir;

  const _TarjetaResultado({
    required this.resultado,
    required this.elegida,
    required this.onElegir,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final mejor = resultado.mejor;
    final confianza = resultado.confianza;
    final info = elegida ?? mejor.info;
    final corregida = elegida != null && elegida!.codigo != mejor.clase;

    final titulo = corregida
        ? info.nombre
        : switch (confianza) {
            Confianza.segura => info.nombre,
            Confianza.dudosa => 'Creo que es ${info.nombre}',
            Confianza.baja => 'No estoy seguro',
          };
    final aviso = corregida
        ? 'Elegiste el material a mano.'
        : switch (confianza) {
            Confianza.segura => null,
            Confianza.dudosa =>
              'No estoy del todo seguro. Si no es, elige el correcto abajo.',
            Confianza.baja => 'Prueba con más luz, de más cerca y con el objeto solo, o elige el material abajo.',
          };

    // La tarjeta va dentro del panel de vidrio del escáner: sin marco propio.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icono, color: info.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontSize: 21),
                ),
              ),
              if (!corregida)
                Pill(
                  texto: '${(mejor.probabilidad * 100).toStringAsFixed(0)}%',
                  color: switch (confianza) {
                    Confianza.segura => c.primarioTexto,
                    Confianza.dudosa => c.recompensaTexto,
                    Confianza.baja => c.alerta,
                  },
                  fontWeight: FontWeight.w700,
                ),
            ],
          ),
          if (aviso != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(aviso, style: TextStyle(color: c.textoSecundario)),
          ],
          if (elegida != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(info.consejo, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            confianza == Confianza.segura && !corregida
                ? 'Otras posibilidades'
                : '¿Cuál es?',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final p in resultado.top)
            _FilaPrediccion(
              prediccion: p,
              seleccionada: elegida?.codigo == p.clase,
              onTap: () => onElegir(p.info),
            ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final otra in clasesConocidas)
                if (!resultado.top.any((p) => p.clase == otra.codigo))
                  ChoiceChip(
                    label: Text(otra.nombre),
                    selected: elegida?.codigo == otra.codigo,
                    onSelected: (_) => onElegir(otra),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Análisis en el teléfono: ${resultado.milisegundosInferencia} ms',
            style: TextStyle(color: c.textoSecundario, fontSize: 12),
          ),
        ],
    );
  }
}

class _FilaPrediccion extends StatelessWidget {
  final PrediccionEscaneo prediccion;
  final bool seleccionada;
  final VoidCallback onTap;

  const _FilaPrediccion({
    required this.prediccion,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final info = prediccion.info;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: seleccionada ? c.primarioSuave : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              seleccionada
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: seleccionada ? c.primarioTexto : c.textoSecundario,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: Text(info.nombre, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: prediccion.probabilidad,
                  minHeight: 8,
                  color: info.color,
                  backgroundColor: c.superficieAlta,
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${(prediccion.probabilidad * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.end,
                style: TextStyle(color: c.textoSecundario, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
