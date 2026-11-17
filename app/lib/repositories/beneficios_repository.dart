import '../models/beneficio.dart';
import '../models/mi_canje.dart';

enum MotivoErrorCanje {
  requiereCuenta,
  saldoInsuficiente,
  sinStock,
  topeAlcanzado,
  beneficioNoDisponible,
  sinSesion,
  sinConexion,
  desconocido,
}

class CanjeException implements Exception {
  final MotivoErrorCanje motivo;
  final Object? causa;

  const CanjeException(this.motivo, [this.causa]);

  String get mensaje => switch (motivo) {
    MotivoErrorCanje.requiereCuenta => 'Para canjear necesitas una cuenta con correo. Créala desde tu Perfil: conservas tus Rebin Points.',
    MotivoErrorCanje.saldoInsuficiente =>
      'No te alcanzan los Rebin Points para este beneficio.',
    MotivoErrorCanje.sinStock => 'Este beneficio se agotó.',
    MotivoErrorCanje.topeAlcanzado =>
      'Ya canjeaste el máximo permitido de este beneficio.',
    MotivoErrorCanje.beneficioNoDisponible =>
      'Este beneficio ya no está disponible.',
    MotivoErrorCanje.sinSesion =>
      'No pudimos identificar tu sesión. Reinicia la app e inténtalo de nuevo.',
    MotivoErrorCanje.sinConexion =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    MotivoErrorCanje.desconocido =>
      'No se pudo canjear. Inténtalo de nuevo en un momento.',
  };

  @override
  String toString() => 'CanjeException($motivo, $causa)';
}

/// Catálogo de beneficios y canjes. Las pantallas dependen solo de esta
/// interfaz (ver regla de repositorios en CLAUDE.md).
abstract class BeneficiosRepository {
  /// Beneficios que se pueden canjear hoy, del más barato al más caro.
  Future<List<Beneficio>> beneficios();

  /// Lanza [CanjeException] si el servidor rechaza el canje.
  Future<ResultadoCanje> canjear(int idBeneficio);

  /// Canjes propios, el más reciente primero.
  Future<List<MiCanje>> misCanjes();
}
