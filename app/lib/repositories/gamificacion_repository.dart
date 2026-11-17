import '../models/resumen_hoy.dart';

/// Por qué la base rechazó una acción de gamificación.
enum MotivoGamificacion {
  congeladoresAlMaximo,
  puntosInsuficientes,
  sinSorpresaHoy,
  sorpresaYaAbierta;

  static MotivoGamificacion? fromCodigo(String? codigo) => switch (codigo) {
    'congeladores_al_maximo' => congeladoresAlMaximo,
    'puntos_insuficientes' => puntosInsuficientes,
    'sin_sorpresa_hoy' => sinSorpresaHoy,
    'sorpresa_ya_abierta' => sorpresaYaAbierta,
    _ => null,
  };
}

class GamificacionException implements Exception {
  final MotivoGamificacion motivo;

  const GamificacionException(this.motivo);

  @override
  String toString() => 'GamificacionException($motivo)';
}

/// Resultado de canjear un congelador: los que quedan guardados y el saldo.
class CompraCongelador {
  final int congeladores;
  final int saldo;

  const CompraCongelador({required this.congeladores, required this.saldo});
}

/// La sorpresa de hoy: aparece algunos días, sin aviso.
class SorpresaHoy {
  final bool disponible;
  final bool abierta;

  /// Rebin Points que da al abrirla.
  final int puntos;

  const SorpresaHoy({
    required this.disponible,
    required this.abierta,
    required this.puntos,
  });

  /// Hay una sorpresa para abrir ahora.
  bool get porAbrir => disponible && !abierta;
}

abstract class GamificacionRepository {
  /// Meta diaria, racha de la semana y congeladores de hoy.
  Future<ResumenHoy> resumenHoy();

  /// Canjea un congelador de racha por Rebin Points. Lanza
  /// [GamificacionException] si ya tiene el máximo o no le alcanza el saldo.
  Future<CompraCongelador> comprarCongelador();

  /// Si hoy hay una sorpresa y si ya se abrió.
  Future<SorpresaHoy> sorpresaHoy();

  /// Abre la sorpresa de hoy. Devuelve los Rebin Points acreditados; lanza
  /// [GamificacionException] si hoy no hay sorpresa o ya se abrió.
  Future<int> abrirSorpresa();
}
