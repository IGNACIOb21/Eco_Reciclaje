import 'package:flutter/material.dart';

/// Advertencias sobre los datos de un punto que la tarjeta y la ficha
/// muestran antes de ir (`avisos` de `app_puntos_cercanos`). El dato no
/// cambia: lo corrige el panel; el aviso se apaga al resolverse el ticket.
enum AvisoPunto {
  /// 2+ personas reportaron que el horario no coincide.
  horario(
    'horario',
    'Horario por verificar',
    'Varias personas reportaron que no coincide con el real.',
    Icons.schedule,
  ),

  /// 2+ personas reportaron que el pin está en otro lugar.
  ubicacion(
    'ubicacion',
    'Ubicación por verificar',
    'Varias personas reportaron que el punto está en otro lugar.',
    Icons.wrong_location_outlined,
  ),

  /// 2+ personas reportaron que recibe otros materiales.
  categorias(
    'categorias',
    'Materiales por verificar',
    'Varias personas reportaron que recibe otros materiales.',
    Icons.category_outlined,
  ),

  /// El QR falta o está dañado: sin él no se registran reciclajes.
  qr(
    'qr',
    'QR no disponible',
    'No se puede registrar reciclajes aquí por ahora.',
    Icons.qr_code_2,
  );

  final String codigo;
  final String titulo;
  final String detalle;
  final IconData icono;

  const AvisoPunto(this.codigo, this.titulo, this.detalle, this.icono);

  static AvisoPunto? desdeCodigo(String codigo) {
    for (final a in values) {
      if (a.codigo == codigo) return a;
    }
    return null;
  }
}
