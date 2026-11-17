/// Una etiqueta rápida y cuántas calificaciones la marcaron.
class EtiquetaContada {
  final String etiqueta;
  final int cantidad;

  const EtiquetaContada(this.etiqueta, this.cantidad);
}

/// Una calificación con comentario, como la ve cualquiera en la ficha: sin id
/// ni correo de quien la escribió.
class Opinion {
  final String alias;
  final int puntuacion;
  final String comentario;
  final DateTime fecha;

  const Opinion({
    required this.alias,
    required this.puntuacion,
    required this.comentario,
    required this.fecha,
  });
}

/// Lo que la ficha muestra de las calificaciones de los últimos 12 meses
/// (`app_opiniones_punto`).
class OpinionesPunto {
  final List<EtiquetaContada> etiquetas;
  final List<Opinion> opiniones;

  const OpinionesPunto({this.etiquetas = const [], this.opiniones = const []});

  static const vacio = OpinionesPunto();

  bool get estaVacio => etiquetas.isEmpty && opiniones.isEmpty;

  factory OpinionesPunto.fromSupabase(Map<String, dynamic> datos) =>
      OpinionesPunto(
        etiquetas: [
          for (final e in (datos['etiquetas'] as List?) ?? const [])
            EtiquetaContada(
              e['etiqueta'] as String,
              (e['cantidad'] as num).toInt(),
            ),
        ],
        opiniones: [
          for (final o in (datos['opiniones'] as List?) ?? const [])
            Opinion(
              alias: o['alias'] as String,
              puntuacion: (o['puntuacion'] as num).toInt(),
              comentario: o['comentario'] as String,
              fecha: DateTime.parse(o['fecha'] as String),
            ),
        ],
      );
}
