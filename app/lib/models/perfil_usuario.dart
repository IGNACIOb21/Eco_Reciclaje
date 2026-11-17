import '../utils/fechas.dart';
import 'actividad_puntos.dart';
import 'usuario.dart';

/// Lo que muestra el Perfil, armado con los datos de la cuenta. Las insignias
/// son los logros reales (`RetosRepository`), no salen de aquí.
class PerfilUsuario {
  final String nombre;
  final String miembroDesde;
  final int puntosTotales;
  final int puntosAcumulados;
  final int racha;
  final int objetosEscaneados;
  final int reportesHechos;
  final List<ActividadPuntos> actividad;

  const PerfilUsuario({
    required this.nombre,
    required this.miembroDesde,
    required this.puntosTotales,
    required this.puntosAcumulados,
    this.racha = 0,
    required this.objetosEscaneados,
    required this.reportesHechos,
    required this.actividad,
  });

  /// Perfil armado 100% con los datos de la cuenta en Supabase.
  factory PerfilUsuario.desdeUsuario(Usuario usuario) {
    return PerfilUsuario(
      nombre: usuario.alias,
      miembroDesde: mesYAnio(usuario.fechaRegistro),
      puntosTotales: usuario.puntosTotales,
      puntosAcumulados: usuario.puntosAcumulados,
      racha: usuario.racha,
      objetosEscaneados: usuario.objetosEscaneados,
      reportesHechos: usuario.reportesHechos,
      actividad: [
        for (final m in usuario.movimientos) ActividadPuntos.desdeMovimiento(m),
      ],
    );
  }
}
