import '../data/mock/recolectores_mock.dart';
import '../models/material_type.dart';
import '../models/postulacion_servicio.dart';
import '../models/recolector_particular.dart';
import 'recolectores_repository.dart';

/// Implementación de maqueta: sirve los recolectores de ejemplo en memoria,
/// simulando la latencia de una llamada real. Las postulaciones se guardan
/// solo mientras vive el objeto.
class RecolectoresRepositoryMock implements RecolectoresRepository {
  /// Si es true, las operaciones lanzan una excepción en vez de devolver datos
  /// — forma simple de mostrar el estado de error en la demo. Ej:
  /// `RecolectoresRepositoryMock(forzarError: true)`.
  final bool forzarError;

  /// Latencia simulada; los tests la ponen en cero.
  final Duration latencia;

  final List<MiPostulacion> _postulaciones = [];

  RecolectoresRepositoryMock({
    this.forzarError = false,
    this.latencia = const Duration(milliseconds: 900),
  });

  Future<void> _simular() async {
    // Sin latencia no se espera: en un test con reloj simulado un Future.delayed
    // nunca terminaría si el propio test lo espera con await.
    if (latencia > Duration.zero) await Future.delayed(latencia);
    if (forzarError) {
      throw Exception('Error simulado: no se pudo completar la operación.');
    }
  }

  @override
  Future<List<RecolectorParticular>> obtenerRecolectores({
    String? comuna,
    List<TipoMaterial> materiales = const [],
  }) async {
    await _simular();
    return recolectoresMock
        .where((r) => comuna == null || r.comunas.contains(comuna))
        .where(
          (r) => materiales.isEmpty || r.materiales.any(materiales.contains),
        )
        .toList();
  }

  @override
  Future<void> postular(PostulacionServicio postulacion) async {
    await _simular();
    // Mismo tope que el servidor: 3 postulaciones en revisión por cuenta.
    final enRevision = _postulaciones.where(
      (p) => p.estado == EstadoPostulacion.pendiente,
    );
    if (enRevision.length >= 3) {
      throw const PostulacionException(
        MotivoErrorPostulacion.limitePostulaciones,
      );
    }
    _postulaciones.insert(
      0,
      MiPostulacion(
        id: '${_postulaciones.length + 1}',
        nombre: postulacion.nombre,
        estado: EstadoPostulacion.pendiente,
        fecha: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<MiPostulacion>> misPostulaciones() async {
    await _simular();
    return List.unmodifiable(_postulaciones);
  }
}
