import '../models/comunidad_hoy.dart';

/// Datos de Comunidad que calcula la base: meta de la comuna, actividad
/// reciente y ranking de la semana.
abstract class ComunidadRepository {
  Future<MetaComuna> metaComuna(String comuna);

  Future<List<ActividadComuna>> actividad(String comuna);

  Future<List<PuestoRanking>> ranking();

  /// Sale del ranking (o vuelve, con [oculto] en false).
  Future<void> ocultarRanking(bool oculto);
}
