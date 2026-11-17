import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/movimiento.dart';
import 'icono_escaner.dart';
import 'presionable.dart';

class DestinoBarra {
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;

  const DestinoBarra({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
  });
}

/// Barra inferior de 5 lugares con el botón de escanear al centro: un círculo
/// con aro, hueco y disco (como el obturador de una cámara) y el ícono de
/// escáner. Los otros cuatro lugares son los [destinos]: dos a cada lado.
class BarraNavegacion extends StatelessWidget {
  /// Exactamente 4 destinos: los dos primeros a la izquierda y los dos
  /// últimos a la derecha del botón.
  final List<DestinoBarra> destinos;
  final int indice;
  final ValueChanged<int> onSeleccion;
  final VoidCallback onEscanear;

  const BarraNavegacion({
    super.key,
    required this.destinos,
    required this.indice,
    required this.onSeleccion,
    required this.onEscanear,
  }) : assert(
         destinos.length == 4,
         'La barra tiene 4 destinos y el botón central',
       );

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget destino(int i) => Expanded(
      child: _Destino(
        destino: destinos[i],
        seleccionado: indice == i,
        onTap: () => onSeleccion(i),
      ),
    );
    // Píldora flotante de color sólido: alrededor no hay fondo propio, así
    // que por los costados se ve el mapa o la pestaña, y la barra se separa
    // con borde claro y sombra suave.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xCCFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x261E2B22),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 84,
            child: Row(
              children: [
                destino(0),
                destino(1),
                Expanded(
                  child: Center(child: BotonEscanear(onTap: onEscanear)),
                ),
                destino(2),
                destino(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destino extends StatelessWidget {
  final DestinoBarra destino;
  final bool seleccionado;
  final VoidCallback onTap;

  const _Destino({
    required this.destino,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = seleccionado ? c.primarioTexto : c.textoSecundario;
    return Semantics(
      selected: seleccionado,
      button: true,
      label: destino.etiqueta,
      excludeSemantics: true,
      child: Presionable(
        onTap: onTap,
        child: SizedBox(
          height: 84,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Movimiento.dur(context, Movimiento.micro),
                curve: Movimiento.entrar,
                width: 56,
                height: 30,
                decoration: BoxDecoration(
                  color: seleccionado ? c.primarioSuave : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  seleccionado ? destino.iconoActivo : destino.icono,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              // Con letra grande la etiqueta se achica entera en vez de
              // cortarse ("Comu", "Servic").
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destino.etiqueta,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón central de escanear: respira entre 100 y 104 % cada 2,4 s, tres veces
/// al abrir, y luego se queda quieto (no gasta batería ni cuadros). Con
/// "reducir animaciones" no respira.
class BotonEscanear extends StatefulWidget {
  /// Verde lima del logo y verde bosque para el ícono encima.
  static const Color lima = Color(0xFFA8DB3C);
  static const Color tinta = Color(0xFF0B4F31);

  final VoidCallback onTap;

  const BotonEscanear({super.key, required this.onTap});

  @override
  State<BotonEscanear> createState() => _BotonEscanearState();
}

class _BotonEscanearState extends State<BotonEscanear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true, count: 6);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final quieto = Movimiento.reducido(context);
    final boton = Container(
      key: const Key('barra-escanear'),
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Aro de vidrio alrededor del disco lima.
        color: const Color(0x99FFFFFF),
        boxShadow: [
          BoxShadow(
            color: c.primario.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BotonEscanear.lima,
        ),
        child: Center(
          child: IconoEscaner(tamano: 30, color: BotonEscanear.tinta),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: 'Escanear un objeto',
      excludeSemantics: true,
      child: Presionable(
        onTap: widget.onTap,
        child: RepaintBoundary(
          child: quieto
              ? boton
              : ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.04).animate(
                    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
                  ),
                  child: boton,
                ),
        ),
      ),
    );
  }
}
