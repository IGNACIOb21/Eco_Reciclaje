import '../models/recolector_particular.dart';

/// Acceso a los recolectores particulares de materiales reciclables. Las
/// pantallas dependen solo de esta interfaz, nunca de la fuente de datos
/// concreta (ver regla de repositorios en CLAUDE.md).
abstract class RecolectoresRepository {
  Future<List<RecolectorParticular>> obtenerRecolectores();
}

// TODO(backend): RecolectorParticular todavía no existe en el modelo de
// datos (docs/modelo-bd.pdf) ni tiene tabla en Supabase. Antes de
// reemplazar el mock hay que definirla (campos, RLS, quién puede publicar
// un recolector) y migrarla — a diferencia de otros repositorios, acá no
// alcanza con "implementar la consulta", falta el diseño de la tabla.
