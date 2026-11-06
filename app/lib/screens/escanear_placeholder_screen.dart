import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// El modelo TFLite de clasificación todavía no está integrado — esta
/// pantalla marca el lugar en la navegación mientras tanto.
class EscanearPlaceholderScreen extends StatelessWidget {
  const EscanearPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colores.fondoMapa,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 44,
                    color: colores.primario,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Escanear objeto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Muy pronto vas a poder apuntar la cámara a un objeto y saber al instante si es reciclable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colores.textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
