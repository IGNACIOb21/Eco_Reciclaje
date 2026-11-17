import 'nivel.dart';

/// Puntos y nivel del usuario tal como llegaron de Supabase. Se guarda una
/// copia en el teléfono (ResumenPuntosStore) para mostrar el progreso aunque
/// no haya conexión.
class ResumenPuntos {
  /// `usuarios.id_usuario` (auth.uid()) de la cuenta a la que pertenecen.
  final String idUsuario;

  /// Saldo para canjear: suma de todos los movimientos (nunca negativo).
  final int saldo;

  /// Puntos ganados (sin restar canjes): define el nivel.
  final int acumulado;

  /// Tabla de niveles (umbrales) de la nube.
  final List<Nivel> niveles;

  /// Cuándo se leyeron de Supabase.
  final DateTime actualizado;

  const ResumenPuntos({
    required this.idUsuario,
    required this.saldo,
    required this.acumulado,
    required this.niveles,
    required this.actualizado,
  });

  Nivel get nivelActual => Nivel.paraPuntos(acumulado, niveles);

  Nivel? get siguienteNivel => nivelActual.siguienteEn(niveles);

  /// Avance dentro del nivel actual (ej. Pro va de 600 a 1500: con 1050 pts
  /// la barra marca 50 %).
  double get progresoNivel {
    final siguiente = siguienteNivel;
    if (siguiente == null) return 1.0;
    final base = nivelActual.puntosMinimos;
    return ((acumulado - base) / (siguiente.puntosMinimos - base)).clamp(
      0.0,
      1.0,
    );
  }

  factory ResumenPuntos.fromJson(Map<String, dynamic> json) => ResumenPuntos(
    idUsuario: json['id_usuario'] as String,
    saldo: (json['saldo'] as num).toInt(),
    acumulado: (json['acumulado'] as num).toInt(),
    niveles: [
      for (final n in json['niveles'] as List)
        Nivel.fromJson(n as Map<String, dynamic>),
    ],
    actualizado: DateTime.parse(json['actualizado'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'saldo': saldo,
    'acumulado': acumulado,
    'niveles': [for (final n in niveles) n.toJson()],
    'actualizado': actualizado.toIso8601String(),
  };
}
